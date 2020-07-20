{% include head.html %}

# アセンブリ生成

この節では，前の節の説明に従って生成した仮想マシンコードを入力とし，現実の計算機アーキテクチャの一つであるMIPSのアセンブリコードを生成する方法について説明する．説明にあたり，[MIPSに関する基本的な知識](textbook/chap05-4.md)は仮定する．

## MIPS の呼出し規約

（本節は一部[MIPSアセンブリ言語入門](textbook/chap05-4.html)と重複する．）

現実のハードウェアが備えている物理レジスタの個数は有限である．そのため，関数（とくに再帰関数）を用いるプログラムではプログラム中のすべての計算を物理レジスタだけで実行することは困難であり，一般に，何らかの方法に則ってプログラム中の各変数の値を格納する場所をメモリ中のどこかへ確保する必要がある．

たとえば，次のようなMiniML4のプログラム（を読みやすさのためにMiniML4のシンタックスではなく同等の言語機能によるOCamlのシンタックスを使って説明したプログラム）
{% highlight ocaml %}
let rec f a = a + 1
and g b = f b
in g 0
{% endhighlight %}
を素朴に実行するだけであれば，プログラム全体で，「関数`f`の引数`a`を格納する場所」「関数`f`を呼び出した結果（返り値）を格納する場所」「関数`g`の引数`b`を格納する場所」「関数`g`の返り値を格納する場所」の計4ワード分を確保すれば十分である．

しかし，そのような素朴な方法だと，たとえば：
{% highlight ocaml %}
let rec fact = fun n -> if n > 0 then n * fact (n + (-1)) else 1
in fact 10
{% endhighlight %}
のような再帰関数`fact`においては，複数の異なる(再帰)呼出しの引数や返り値の格納場所が同じ領域を使うことになり，実行がおかしくなってしまう．具体的には，関数呼出し`fact 9`の直後には，その返り値に対し$10$を掛ける必要があるが，関数呼出し`fact 10`の引数である値$10$は，`fact`の引数を格納するただ一つの場所に置かれていたため，すでに値$9$で上書きされ失われてしまっている（正確には，さらに$8, 7,\ldots,0$で上書きされているが，ともかく$10$という値はもはや存在しない）．

結局のところ，関数定義単位で必要な領域のサイズを求め，その総和分を確保するだけでは不十分であり，関数呼出し毎に異なる場所を確保する必要があることが分かる．そこで，関数機能を持つプログラミング言語（関数型言語に限らず，たとえばC言語なども含む）の処理系では，通常，呼出し/リターンの制御構造に対応できるよう，各関数呼出しの実行に必要となるメモリ領域を管理するためのデータ構造として，LIFO (last-in first-out)で管理するスタックを用いる．また，このスタックは，呼出し側が関数呼出しの次に実行するべき命令のアドレス（**リターンアドレス (return address)**と呼ばれる）を保存しておくためにも用いられる（詳細は後述）．

原理的には，ここまでに説明したように各関数の実行で必要となるすべての引数・返り値・局所変数（ならびにリターンアドレス）のための場所をスタック上に必ず確保することにすれば，再帰関数を含むようなプログラムであっても正しく実行できるが，それだけだと，プログラム実行中に計算されるすべての値をメモリ領域にいちいち格納するため，レジスタを有効活用できておらず実行性能はあまり良くない．たとえば，返り値を格納する場所をスタック上のある場所に定めてしまうと，（とくにレジスタで計算を行うRISC系のハードウェアにおいては）呼び出された側が最後にスタックのその場所に返り値をストアしたすぐ後に，呼出し側が同じ場所からレジスタへロードするということが頻繁に起こる．この実行オーバヘッドは，たとえば「関数呼出しの返り値は必ず`v0`レジスタを使って受け渡しする」と決めておけば避けることができる．まったく同様に，引数の受け渡しについてもレジスタの使い方に関し何らかの約束事を決めておけば，実行効率を良くすることができる．

以上のようなスタックとレジスタの使い方に関する約束事は，レジスタの種類や個数，関数の呼出し/リターンに用いることのできるジャンプ命令の詳細な振舞いなどに依存するため，通常，計算機アーキテクチャ毎に定められている．関数呼出しに関するそのような約束事は，一般に**呼出し規約 (calling convention)**と呼ばれる．

なお，本講義で作成するMiniML4-コンパイラはMIPSアセンブリをターゲットとしているため，本来であればMIPSの呼出し規約に厳密に従うべきところだが，説明を簡単にするため，少し簡略化した独自の呼出し規約を用いている．より本格的なプログラミング言語や言語処理系との互換性を気にする場合には，この資料に書かれている説明を理解した後に各自でさらに勉強して欲しい（「MIPS calling convention」などと検索すれば，たくさんの情報を得られる）．

## MiniML4-コンパイラにおける呼出し規約

まず，関数の返り値については先程触れたように，`v0`レジスタを介して受け渡すことにする．また，MiniML4-言語におけるすべての関数は引数を1つしか受け取らないため，その唯一の引数は`a0`レジスタを介して受け渡すことにする．

各関数を実行するために必要なスタック上の連続領域（**フレーム (frame)**と呼ぶ）は，以下の図に示すように，スタックの一番上（メモリアドレスは下位の方）に確保される．

```
上位アドレス
               |             |
               | ...         |
               +-------------+         
               | ra          |        |
               | saved a0    |        | スタックの伸びる向き
               | local 4n    |        V
               | ...         |
               | local 4     |
               | local 0     |<- $sp
               +-------------+
下位アドレス
```

フレーム中に含まれる各データの説明は以下のとおりである．
- リターンアドレス (`ra`): このフレームを使っている関数を呼び出した関数が，その関数呼出しの次に実行する命令のアドレスを退避するための場所．さらに別の関数を呼ぶことがなければ必ずしも退避する必要はないが，簡単化のため，必ずフレームの一番上に退避することにしている．
- 退避された`a0`レジスタ (`saved a0`): このフレームを使っている関数が実引数を`a0`レジスタにセットして他の関数を呼び出す際，すでに`a0`レジスタに入っている自分自身のパラメータを退避するための場所．関数呼出し以降にパラメータを使わないのであれば必ずしも退避する必要はない（が，次節のコード生成では，簡単化のため必ず退避することにしている）．
- 局所変数 (`local 0〜4n`): 関数本体で$\mathbf{let}$により束縛する局所変数の値を格納するための場所．$\mathcal{T}$で$\mathbf{local}(0)$を関数からの返り値を格納する場所として使用したので，それに則って，局所変数の個数が$N$個ならば局所変数を格納するための領域が$4N+4$バイトになっている．

なお，`sp`レジスタ（スタックポインタ）は，常にスタック最上部（フレームの一番下）を指すようにする．したがって，$i$番目 $(1 \le i \le N)$ の局所変数が格納されている領域はアドレス`$sp + 4i`となる．また，`saved a0` のアドレスは`$sp + 4N + 4`，リターンアドレスのアドレスは`$sp + 4N + 8`となる．

以下は，上記のスタックレイアウトに基づいて関数呼出しを行う手順の概要である（詳細な手順については次節を参照）．
- 呼出し側は，`a0`レジスタの値を（自身の）`saved a0` に退避してから，関数呼出しの実引数を`a0`レジスタにセットする．
- `jal`あるいは`jalr`命令によって呼び出される関数の先頭へジャンプする．呼出し側の次の命令のアドレスは`ra`レジスタにセットされる．
- （以下，呼び出された関数側で実行）`sp`レジスタを必要なだけ下げる．
- `ra`レジスタに入っているリターンアドレスを，スタックの所定の位置に退避する．
- 関数本体を実行し，求まった返り値を`v0`レジスタにセットする．
- スタック中のリターンアドレスをレジスタに戻す．
- 関数実行開始時に下げた分と同じ分だけ`sp`レジスタを上げることで，スタックからフレームを取り除く．
- `jr`命令によってスタックから`ra`に取り出したリターンアドレスへリターンする．
- （呼出し側で実行）`v0`レジスタから返り値を取り出し，さらに，退避しておいた`saved a0`を`a0`レジスタに戻す．

最後に，以下の簡単なOCamlコード：
{% highlight ocaml %}
let rec f a = g (a+1)
and g b = let x = b + b in
          let y = x * x in
          let z = y - 1 in
            z
in f 0
{% endhighlight %}
の実行中，関数`f`から関数`g`を呼び出す前後のスタックの状態を以下に示す．

### 関数`g`を呼び出す直前
```
      +-------------+
   |  | saved a0: - |
   |  |   ...       |
   V  | [f's frame] |
      |   ...       |<- $sp
      +-------------+







         $a0 = 0
```

### `g` を呼び出した直後

```
      +-------------+
   |  | saved a0: 0 |
   |  |   ...       |
   V  | [f's frame] |
      |   ...       |
      +-------------+
      |     ra      |
      | saved a0: - |
      |     z: -    |
      |     y: -    |
      |     x: -    |<- $sp
      +-------------+

        $a0 = 1
```

### `g` からのリターン直後

```
      +-------------+
   |  | saved a0: 0 |
   |  |   ...       |
   V  | [f's frame] |
      |   ...       |<- $sp
      +-------------+
  
  
  

  
  

         $a0 = 0
         $v0 = 3
```

### 現実の呼出し規約に関する余談

一般のプログラミング言語では，多引数関数を定義できたり，引数の数が固定ではない（可変長引数と呼ばれる）関数を定義できたりする．また，関数本体の実行中に使用するメモリサイズを正確に求めることが難しいこともある（たとえば，スタック上に任意サイズのメモリ領域を確保できるC言語の`alloca`関数を使用した場合など）．そのような場合，物理レジスタに収まりきらない引数をスタックに置く必要がある．それに加え，実行中に位置が一定ではない`sp`レジスタからの相対アドレスを用いてスタック中のパラメータおよび局所変数へアクセスしようとすると，コンパイル時に求める必要のある相対アドレスの計算が複雑になる．

そこで，現実のコンパイラにおいては，`sp`レジスタとは別に，関数フレームの`sp`とは反対側（典型的には`ra`の入っているあたり）を常に指し続ける`fp`レジスタを別に用意しておき，パラメータや局所変数へのアクセスには`fp`レジスタからの相対アドレスを用いるのが一般的である．ただし，リターンアドレスと同様に，呼出し側の`fp`レジスタの値もスタック中に退避する手間がさらに必要となる．

## アセンブリ生成

以上を踏まえて，$\mathcal{V}$のプログラムをMIPSアセンブリに変換する関数$\mathcal{G}$の定義を示す．

### オペランドの変換

オペランドの変換$\mathcal{G}_{r}{\mathit{oprd}}$は以下の通りである．

$$
      \begin{array}{rcl}
        \mathcal{G}_{r}(\mathbf{param}(1)) &=&
        \begin{array}[t]{ll}
          \texttt{move} & r,\texttt{\$a0}\\
        \end{array}\\
        \mathcal{G}_{r}(\mathbf{local}(n)) &=&
        \begin{array}[t]{l}
          \texttt{lw} & r,n(\texttt{\$sp})\\
        \end{array}\\
        \mathcal{G}_{r}(\mathbf{labimm}(l)) &=&
        \begin{array}[t]{l}
          \texttt{la} & r,l\\
        \end{array}\\
        \mathcal{G}_{r}(\mathbf{imm}(n)) &=&
        \begin{array}[t]{l}
          \texttt{li} & r,n\\
        \end{array}\\
      \end{array}
$$

オペランドの変換は$\mathcal{G}\_{r}(\mathit{oprd})$で行う．この変換では「$\mathit{oprd}$に格納されている値をレジスタ$r$にロードする」MIPSアセンブリが生成される．各ケースの説明は以下の通りである．
- $\mathcal{G}\_{r}(\mathbf{param}(1))$: $\mathbf{param}(1)$（関数の第一引数）をレジスタ$r$にロードする．現在の$\mathcal{V}$では一引数関数のみが定義できるため$\mathbf{param}(1)$についてのみ定義されている．関数の引数は関数呼び出し規約からレジスタ$\mathtt{\$a0}$に格納されているので，この内容を$r$にロードするために$\texttt{move}$命令を用いている．
- $\mathcal{G}\_{r}(\mathbf{local}(n))$: $\mathbf{local}(n)$に格納されている値をレジスタ$r$にロードする．$\mathbf{local}(n)$は関数呼び出し規約から$n(\mathtt{\$sp})$に格納されているので，これをレジスタ$r$にロードするために$\texttt{lw}$命令を用いる．
- $\mathcal{G}\_{r}(\mathbf{labimm}(l))$: コード中のラベル$l$のアドレスを$r$にロードする．\footnote{このようにレジスタにコード中のアドレスをロードすることで，コード中の「場所」を値として保持することが可能となる．これは高階関数の実装で必要になる．}このために$\texttt{la}$命令を用いている．$l$はラベル$l$をMIPS内で解釈できる記号に変換したものである．
- $\mathcal{G}\_{r}(\mathbf{imm}(n))$: 整数定数$n$をレジスタ$r$にロードする．これは$\texttt{li}$命令を用いて実装することができる．

### 命令の変換

命令の変換を行う関数$\mathcal{G}_{n}(i)$は，$\mathcal{V}$の命令$i$を，局所変数用に$n$バイトを使う関数の内部にあると仮定して実行するMIPSの命令列を生成する．この$n$はフレーム内に格納されている値にアクセスする際に，そのアドレスの$\mathtt{\$sp}$からのオフセットを計算するために用いられる．定義は以下の通りである．

$$
      \begin{array}{rcl}
        \mathcal{G}_{n}(\MOVE{\mathbf{local}(\offset)}{\mathit{oprd}}) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\TMPREGONE}(\mathit{oprd})\\
          \ST \quad \TMPREGONE, \offset(\texttt{\$sp})\\
        \end{array}\\
        \mathcal{G}_{n}(\BINOP{\mathbf{local}(\offset)}{\OP}{\mathit{oprd}_1,\mathit{oprd}_2}) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\TMPREGONE}(\mathit{oprd}_1)\\
          \mathcal{G}_{\TMPREGTWO}(\mathit{oprd}_2)\\
          \sem{\OP} \quad \TMPREGONE, \TMPREGONE, \TMPREGTWO\\
          \ST \quad \TMPREGONE,\offset(\texttt{\$sp})\\
        \end{array}\\
        \mathcal{G}_{n}(\texttt{la}BEL{l})) &=&
        \begin{array}[t]{l}
          l\mathtt{ {l} }
        \end{array}\\
        \mathcal{G}_{n}(\BRIF{\mathit{oprd}}{l}) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\TMPREGONE}(\mathit{oprd})\\
          \BGTZ \quad \TMPREGONE,l\\
        \end{array}\\
        \mathcal{G}_{n}(\GOTO{l}) &=&
        \begin{array}[t]{l}
          \JUMP \quad l
        \end{array}\\
        \mathcal{G}_{n}(\CALL{\mathbf{local}(\offset)}{\mathit{oprd}_f(\mathit{oprd}_1)}) &=&
        \begin{array}[t]{l}
          \SAVE_{n+4}(\texttt{\$a0})\\
          \mathcal{G}_{\texttt{\$a0}}(\mathit{oprd}_1)\\
          \mathcal{G}_{\TMPREGONE}(\mathit{oprd}_f)\\
          \JALR \quad \RA,\TMPREGONE\\
          \ST \quad \RETREG,\offset(\texttt{\$sp})\\
          \RESTORE_{n+4}(\texttt{\$a0})\\
        \end{array}\\
        \mathcal{G}_{n}(\RETURN(\mathit{oprd})) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\RETREG}(\mathit{oprd})\\
          \EPILOGUE(n)\\
          \JR \quad \RA\\
        \end{array}\\
      \end{array}
$$

各ケースの説明は以下の通りである．
\begin{description}
\item[$\mathcal{G}_{n}(\MOVE{\mathbf{local}(\offset)}{\mathit{oprd}})$]: この命令は
  「$\mathit{oprd}$に格納されている値を$\mathbf{local}(\offset)$に格納する」ように
  動作する．そのためにまず$\mathit{oprd}$の値を求め，一時レジスタ
  $\TMPREGONE$に格納する命令を生成し
  （$\mathcal{G}_{\TMPREGONE}(\mathit{oprd})$）その後$\TMPREGONE$に格納されて
  いるアドレスからレジスタ$r$に値をロードする命令$\ST \quad
  \TMPREGONE, \offset(\texttt{\$sp})$を生成する．
\item[$\BINOP{\mathbf{local}(\offset)}{\OP}{\mathit{oprd}_1,\mathit{oprd}_2}$]:
  $\mathit{oprd}_1$に格納されている値をレジスタ$\TMPREGONE$に
  （$\mathcal{G}_{\TMPREGONE}(\mathit{oprd}_1)$），$\mathit{oprd}_2$に格納されてい
  る値をレジスタ$\TMPREGTWO$に（$\mathcal{G}_{\TMPREGONE}(\mathit{oprd}_1)$）
  それぞれロードする．その上で，レジスタ$\TMPREGONE$の値とレジスタ
  $\TMPREGTWO$の値を引数として演算子$\OP$によって計算し，その結果を
  $\TMPREGONE$にロード（$\sem{\OP} \quad \TMPREGONE, \TMPREGONE,
    \TMPREGTWO$）する．定義を簡潔にするために，演算子$\OP$に対応する
  MIPSの命令を$\sem{\OP}$で表し，具体的に使わなければならない命令を
  $\sem{-}$の定義の中に押し込めている．（例えば
    $\sem{{+}}=\mathtt{addu}, \sem{{-}}=\mathtt{mulou}$とすればよい．）
  最後にレジスタ$\TMPREGONE$の値を$\mathbf{local}(\offset)$にストア（$\ST
    \quad \TMPREGONE,\offset(\texttt{\$sp})$）している．$\offset$バイト目のロー
  カル変数のアドレスが$\texttt{\$sp}+\offset$であることに注意せよ．
\item[$\texttt{la}BEL{l}$]: ラベル$l$を生成（$l\mathtt{{:}}$）して
  いる．ここで$l$はラベル$l$をMIPSアセンブリ内でラベルとして解釈
  できる識別子に変換したものである．この変換は一対一対応でさえあればど
  のように定義しても良いが，メインのプログラムを表すラベル
  $l_{\mathit{main}}$は，MIPSアセンブリ内のエントリポイント（プログラ
    ムの実行時に最初に制御が移される場所）を表す$\mathtt{main}$という
  ラベル名に変換する必要がある．
\item[$\mathcal{G}_{n}(\BRIF{\mathit{oprd}}{l})$]: まず$\mathit{oprd}$に格納されて
  いる値をレジスタ$\TMPREGONE$に格納する．その上で，レジスタ
  $\TMPREGONE$が$\TRUE$を表す非ゼロ値であれば$l$にジャンプ
  （$\BGTZ \quad \TMPREGONE,l$）する．
\item[$\mathcal{G}_{n}(\GOTO{l})$]: 無条件でラベル$l$にジャンプ
  （$\JUMP \quad l$）する．
\item[$\mathcal{G}_{n}(\CALL{\mathbf{local}(\offset)}{\mathit{oprd}_f(\mathit{oprd}_1)})$]:
  関数呼び出しを行う際には，関数呼び出し規約に従ってレジスタの内容を退
  避・復帰したり，引数をセットしたり，返り値を取得したりしなければなら
  ない．今回のコンパイラにおいては，関数の呼び出し側では，
  \pageref{fig:callingConvention}ページで説明した通り，(1) レジスタ
  \verb|a0|の値の退避，(2) レジスタ\verb|v0|に格納されている返り値の取
  得，(3) 退避しておいたレジスタ\verb|a0|の値の復帰を行う必要がある．
  レジスタ値の退避・復帰を行う命令列は他のケースでも使用するので，それ
  ぞれテンプレ化して図~\ref{fig:auxiliary}に「アドレス$\texttt{\$sp}+n$にレジス
    タ$r$の内容を退避する命令列$\SAVE_n(r)$」と「アドレス$\texttt{\$sp}+n$に退避
    したレジスタ$r$の内容を復帰する命令列$\RESTORE_n(r)$」として定義し
  てある．$\SAVE$と$\RESTORE$を使うと，関数呼び出し前に実行されるべき
  命令列は以下の通りとなる．
  \begin{enumerate}
  \item レジスタ$\texttt{\$a0}$をメモリ上のアドレス$\texttt{\$sp}+n+4$に退避
    ($\SAVE_{n+4}(\texttt{\$a0})$) する．$\texttt{\$a0}$は今から行う関数呼び出
    しのための実引数で上書きされるからである．
  \item $\mathit{oprd}_1$に格納されている実引数を$\texttt{\$a0}$にロードする．
  \item $\mathit{oprd}_f$に格納されているラベル (=コード上のアドレス) を
    $\TMPREGONE$にロードする．
  \item $\JALR$命令を使って$\TMPREGONE$に格納されているラベルにジャン
    プする．$\JALR$命令の第一引数$\RA$には，ジャンプ先からリターンする
    ときに帰ってくるべきコード上のアドレス (=この命令の次の行) がセッ
    トされる\footnote{なので，$\RA$はこの命令の実行前にどこかに退避さ
      れていなければならないが，これは関数定義のアセンブリ生成のところ
      で説明する．}．
  \end{enumerate}
  この次の行からは，この後呼び出された関数が実行されリターンした後に実
  行されるべき命令列が書いてある．
  \begin{enumerate}
  \item レジスタ $\RETREG$ に格納されているはずの（関数呼び出し規約を
    参照のこと）リターンされた値を$\mathbf{local}(\offset)$，すなわち
    $\texttt{\$sp}+\offset$に$\ST$命令を使ってストアする．
  \item $\texttt{\$sp}+n+4$に呼び出し前に退避しておいたレジスタ$\texttt{\$a0}$の内容
    を復帰させる ($\RESTORE_{n+4}(\texttt{\$a0})$)．
  \end{enumerate}
  以上の命令列が実際に正しく関数呼び出しを実行することを確認するために
  は，関数呼出し時の命令のみではなく，リターン命令
  ($\mathcal{G}_n(\RETURN(\mathit{oprd}))$) や関数定義側でどのような命令列が生
  成されるかも確認することがある．前者についてはすぐ，後者については後
  で$\mathcal{G}(d)$の定義を説明する際にそれぞれ説明する．
\item[$\RETURN(\mathit{oprd})$]: $\mathit{oprd}$に格納されている値を呼び出し側に
  返さなければならない．関数呼び出し規約によれば，関数がリターンする前
  には以下の処理を行う必要がある: (1) 返り値をレジスタ$\RETREG$にロー
  ド, (2) 関数の先頭でフレーム内に退避しておいた$\RA$の値を復帰，(3)
  $\texttt{\$sp}$レジスタの値を先頭で下げた分だけ上げる (すなわち，現在のフレー
  ムに使っていたスタック上の領域を解放する), (4) $\JR$命令を用いて
  $\RA$に格納されたアドレスにリターンする．具体的には以下の命令列が生
  成される:
  \begin{enumerate}
  \item $\mathit{oprd}$に格納されている値を返り値を格納すべきレジスタ
    ($\RETREG$) にロード ($\mathcal{G}_{\RETREG}(\mathit{oprd})$) する．
  \item $\RA$の値の復帰とフレームの解放を行う．定義中では
    $\EPILOGUE(n)$でこの処理を行う命令を生成している．$\EPILOGUE(n)$は
    ローカルな記憶領域のサイズが$n$のフレームを持つ関数呼び出しのリター
    ン前の処理を行う命令列で，退避しておいた$\RA$の復帰
    $\RESTORE_{n+8}(\RA)$と，$\texttt{\$sp}$の値の更新を行う．
  \item $\JR$命令で復帰した$\RA$にリターンする．
  \end{enumerate}
\end{description}

関数定義$(l \mid i_1 \dots i_m \mid n)$に対応する命令列$\mathcal{G}((l
\mid i_1 \dots i_m \mid n))$は以下のアセンブリを生成する．
\begin{enumerate}
\item この関数のラベルを生成する ($l\mathtt{:}$)．
\item 関数本体の先頭で行わなければならない処理を行う命令列を生成する．
  関数呼び出し規約によれば以下の処理を行う必要がある:
  \begin{enumerate}
  \item レジスタ$\texttt{\$sp}$の値を更新して今から使うフレームを確保する．
  \item レジスタ$\RA$の値をフレーム内の所定の位置に退避する．
  \end{enumerate}
  以上の処理を行うための命令列を$\PROLOGUE(n)$として
  図~\ref{fig:auxiliary}に定義している．ここで$n$はこの関数内で使用す
  る局所変数のための記憶領域のサイズである．$\PROLOGUE(n)$は初めにフレー
  ムのサイズ分$\texttt{\$sp}$の値を$\ADDIU$命令を用いて減らす．フレームのサイズ
  は，(局所変数用領域)+($\RA$退避先用の領域4バイト)+($\texttt{\$a0}$退避先
  用の領域4バイト)なので$n+8$である．その後，$\RA$をフレーム内の所定の
  場所に退避している．
\end{enumerate}

最後に，プログラム$(d_1 \dots d_m \mid i_1 \dots i_n \mid k)$のアセンブリ生成の定義を説明しよう．まず先頭で，以降にかかれている情報がプログラムである旨を示す$\mathtt{.text}$ディレクティブを生成している．その次の行には，アセンブリ中の$\mathtt{main}$というラベル名がグローバルなラベル，すなわち外部から見える名前であることが宣言されている．その後$d_1$から$d_m$までのアセンブリを順番に生成した後に，$\sem{l_{\mathit{main}}}\mathtt{:}$に続いて，メインのプログラムを実行するためのフレームの確保を$\PROLOGUE(k)$で行い ($k$はフレームのサイズ)，命令列$i_1 \dots i_n$に対応するアセンブリを生成する．

\begin{figure}
  \footnotesize
  \begin{flushleft}
    \begin{boxedminipage}{\textwidth}
      （$\sem{\OP}$は$\mathcal{V}$の$\OP$に対応するMIPSの命令，$l$は
        ラベル名$l$をMIPSアセンブリ内のラベルとして解釈できるようにし
        た表現である．ただし，$\sem{l_{\mathit{main}}} =
        \mathtt{main}$とする．）
      
      \fbox{Definition of $\mathcal{G}_{r}(\mathit{oprd})$}

      \fbox{Definition of $\mathcal{G}_{n}(i)$}\\
      
      \fbox{Definition of $\mathcal{G}(d)$}
      \[
      \begin{array}{rcl}
        \mathcal{G}((l \mid i_1 \dots i_m \mid n)) &=&
        \begin{array}[t]{l}
          l\mathtt{:}\\
          \PROLOGUE(n)\\
          \mathcal{G}_{n}(i_1)\\
          \dots\\
          \mathcal{G}_{n}(i_m)\\
          % \EPILOGUE(n)\\
        \end{array}\\
      \end{array}
      \]

      \fbox{Definition of $\mathcal{G}(P)$}
      \[
      \begin{array}{rcl}
        \mathcal{G}((d_1 \dots d_m \mid i_1 \dots i_n \mid k)) &=&
        \begin{array}[t]{l}
          \mathtt{.text}\\
          \mathtt{.globl\ main}\\
          \mathcal{G}(d_1)\\
          \dots\\
          \mathcal{G}(d_m)\\
          \sem{l_{\mathit{main}}}\mathtt{:}\\
          \PROLOGUE(k)\\
          \mathcal{G}_k(i_1)\\
          \dots\\
          \mathcal{G}_k(i_n)\\
          % \EPILOGUE(k)\\
        \end{array}\\
      \end{array}
      \]
    \end{boxedminipage}
  \end{flushleft}
  \caption{アセンブリ生成の定義．}
  \label{fig:codegen}
\end{figure}

\begin{figure}
  \footnotesize
  \begin{flushleft}
    \begin{boxedminipage}{\textwidth}
      （$\sem{\OP}$は$\mathcal{V}$の$\OP$に対応するMIPSの命令名である．）
      
      \fbox{Definition of $\PROLOGUE(n)$}
      
      \[
      \begin{array}{rcl}
        \PROLOGUE(n) &=&
        \begin{array}[t]{l}
          \ADDIU \quad \texttt{\$sp},\texttt{\$sp},-n-8\\
          \SAVE_{n+8}(\RA)\\
        \end{array}\\
      \end{array}
      \]
        
      \fbox{Definition of $\EPILOGUE(n)$}

      \[
      \begin{array}{rcl}
        \EPILOGUE(n) &=&
        \begin{array}[t]{l}
          \RESTORE_{n+8}(\RA)\\
          \ADDIU \quad \texttt{\$sp},\texttt{\$sp},n+8\\
          % \JR \quad \RA\\
        \end{array}\\
      \end{array}
      \]

      \fbox{Definition of $\SAVE_n(r)$}

      \[
      \begin{array}{rcl}
        \SAVE_n(r) &=&
        \begin{array}[t]{l}
          \ST \quad r,n(\texttt{\$sp})
        \end{array}\\
      \end{array}
      \]

      \fbox{Definition of $\RESTORE_n(r)$}

      \[
      \begin{array}{rcl}
        \RESTORE_n(r) &=&
        \begin{array}[t]{l}
          \texttt{lw} \quad r,n(\texttt{\$sp})
        \end{array}\\
      \end{array}
      \]

    \end{boxedminipage}
  \end{flushleft}
  \caption{アセンブリ生成用補助関数の定義．}
  \label{fig:auxiliary}
\end{figure}

