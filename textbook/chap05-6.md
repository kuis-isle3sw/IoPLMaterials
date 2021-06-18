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

オペランドの変換$\mathcal{G}_{r}(\mathit{oprd})$は以下の通りである．

$$
      \begin{array}{rcl}
        \mathcal{G}_{r}(\mathbf{param}(1)) &=&
        \begin{array}[t]{ll}
          \texttt{move} & r,\mathtt{\$a0}\\
        \end{array}\\
        \mathcal{G}_{r}(\mathbf{local}(n)) &=&
        \begin{array}[t]{l}
          \texttt{lw} & r,n(\mathtt{\$sp})\\
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
- $\mathcal{G}\_{r}(\mathbf{labimm}(l))$: コード中のラベル$l$のアドレスを$r$にロードする．このために$\texttt{la}$命令を用いている．（このようにレジスタにコード中のアドレスをロードすることで，コード中の「場所」を値として保持することが可能となる．これは高階関数の実装で必要になる．）
- $\mathcal{G}\_{r}(\mathbf{imm}(n))$: 整数定数$n$をレジスタ$r$にロードする．これは$\texttt{li}$命令を用いて実装することができる．

### 命令の変換

命令の変換を行う関数$\mathcal{G}_{n}(i)$は，$\mathcal{V}$の命令$i$を，局所変数用に$n$バイトを使う関数の内部にあると仮定して実行するMIPSの命令列を生成する．この$n$はフレーム内に格納されている値にアクセスする際に，そのアドレスの$\mathtt{\$sp}$からのオフセットを計算するために用いられる．定義は以下の通りである．

$$
      \begin{array}{rcl}
        \mathcal{G}_{n}(\mathbf{local}(\mathit{ofs}) \leftarrow \mathit{oprd}) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\mathtt{\$t0}}(\mathit{oprd})\\
          \mathtt{sw} \quad \mathtt{\$t0}, \mathit{ofs}(\mathtt{\$sp})\\
        \end{array}\\
        \mathcal{G}_{n}(\mathbf{local}(\mathit{ofs}) \leftarrow \mathit{bop} \; \mathit{oprd}_1,\mathit{oprd}_2) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\mathtt{\$t0}}(\mathit{oprd}_1)\\
          \mathcal{G}_{\mathtt{\$t1}}(\mathit{oprd}_2)\\
          [\![\mathit{bop}]\!] \quad \mathtt{\$t0}, \mathtt{\$t0}, \mathtt{\$t1}\\
          \mathtt{sw} \quad \mathtt{\$t0},\mathit{ofs}(\mathtt{\$sp})\\
        \end{array}\\
        \mathcal{G}_{n}(l:) &=&
        \begin{array}[t]{l}
          l:
        \end{array}\\
        \mathcal{G}_{n}(\mathbf{if} \; \mathit{oprd} \ne 0 \; \mathbf{then} \; \mathbf{goto} \; l) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\mathtt{\$t0}}(\mathit{oprd})\\
          \mathtt{bgtz} \quad \mathtt{\$t0},l\\
        \end{array}\\
        \mathcal{G}_{n}(\mathbf{goto} \; l) &=&
        \begin{array}[t]{l}
          \mathtt{j} \quad l
        \end{array}\\
        \mathcal{G}_{n}(\mathbf{local}(\mathit{ofs}) \leftarrow \mathit{oprd}_f(\mathit{oprd}_1)) &=&
        \begin{array}[t]{l}
          \mathit{Save}_{n+4}(\mathtt{\$a0})\\
          \mathcal{G}_{\mathtt{\$a0}}(\mathit{oprd}_1)\\
          \mathcal{G}_{\mathtt{\$t0}}(\mathit{oprd}_f)\\
          \mathtt{jalr} \quad \mathtt{\$ra},\mathtt{\$t0}\\
          \mathtt{sw} \quad \mathtt{\$v0},\mathit{ofs}(\mathtt{\$sp})\\
          \mathit{Restore}_{n+4}(\mathtt{\$a0})\\
        \end{array}\\
        \mathcal{G}_{n}(\mathbf{return} \; \mathit{oprd}) &=&
        \begin{array}[t]{l}
          \mathcal{G}_{\mathtt{\$v0}}(\mathit{oprd})\\
          \mathit{Epilogue}(n)\\
          \mathtt{jr} \quad \mathtt{\$ra}\\
        \end{array}\\
      \end{array}
$$

各ケースの説明は以下の通りである．
- $\mathcal{G}\_{n}(\mathbf{local}(\mathit{ofs}) \leftarrow \mathit{oprd})$: この命令は「$\mathit{oprd}$に格納されている値を$\mathbf{local}(\mathit{ofs})$に格納する」ように動作する．そのためにまず$\mathit{oprd}$の値を求め，一時レジスタ$\mathtt{\$t0}$に格納する命令を生成し（$\mathcal{G}_{\mathtt{\$t0}}(\mathit{oprd})$）その後$\mathtt{\$t0}$に格納されているアドレスからレジスタ$r$に値をロードする命令 $\mathtt{sw} \quad \mathtt{\$t0}, \mathit{ofs}(\mathtt{\$sp})$ を生成する．
- $\mathbf{local}(\mathit{ofs}) \leftarrow \mathit{bop} \; \mathit{oprd}\_1,\mathit{oprd}\_2$: $\mathit{oprd}\_1$に格納されている値をレジスタ$\mathtt{\$t0}$に（$\mathcal{G}\_{\mathtt{\$t0}}(\mathit{oprd}\_1)$），$\mathit{oprd}\_2$に格納されている値をレジスタ$\mathtt{\$t1}$に（$\mathcal{G}\_{\mathtt{\$t1}}(\mathit{oprd}_2)$）それぞれロードする．その上で，レジスタ$\mathtt{\$t0}$の値とレジスタ$\mathtt{\$t1}$の値を引数として演算子$\mathit{bop}$によって計算し，その結果を$\mathtt{\$t0}$にロード（$[\\![\mathit{bop}]\\\!] \quad \mathtt{\$t0}, \mathtt{\$t0}, \mathtt{\$t1}$）する．定義を簡潔にするために，演算子$\mathit{bop}$に対応する MIPSの命令を$[\\![\mathit{bop}]\\\!]$で表し，具体的に使わなければならない命令を$[\\![\dots]\\\!]$の定義の中に押し込めている．（例えば$[\\![{+}]\\\!] = \mathtt{addu}$などとする．）最後にレジスタ$\mathtt{\$t0}$の値を$\mathbf{local}(\mathit{ofs})$にストア（$\mathtt{sw} \quad \mathtt{\$t0},\mathit{ofs}(\mathtt{\$sp})$）している．$\mathit{ofs}$バイト目のローカル変数のアドレスが$\mathtt{\$sp}+\mathit{ofs}$であることに注意せよ．
- $l:$: ラベル$l$を生成（$l\mathtt{ {:} }$）している．メインのプログラムを表すラベル$l_{\mathit{main}}$は，MIPSアセンブリ内のエントリポイント（プログラムの実行時に最初に制御が移される場所）を表す$\mathtt{main}$というラベル名とする必要がある．
- $\mathcal{G}_{n}(\mathbf{if} \; \mathit{oprd} \ne 0 \; \mathbf{then} \; \mathbf{goto} \; l)$: まず$\mathit{oprd}$に格納されている値をレジスタ$\mathtt{\$t0}$に格納する．その上で，レジスタ$\mathtt{\$t0}$が$\mathbf{true}$を表す非ゼロ値であれば$l$にジャンプ（$\mathtt{bgtz} \quad \mathtt{\$t0},l$）する．
- $\mathcal{G}_{n}(\mathbf{goto} \; l)$: 無条件でラベル$l$にジャンプ（$\mathtt{j} \quad l$）する．
- $\mathcal{G}_{n}(\mathbf{local}(\mathit{ofs}) \leftarrow \mathbf{call} \; \mathit{oprd}_f \; \mathit{oprd}_1$: 関数呼び出しを行う際には，関数呼び出し規約に従ってレジスタの内容を退避・復帰したり，引数をセットしたり，返り値を取得したりしなければならない．今回のコンパイラにおいては，関数の呼び出し側では，すでに説明した通り，(1) レジスタ`a0`の値の退避，(2) レジスタ`v0`に格納されている返り値の取得，(3) 退避しておいたレジスタ`a0`の値の復帰を行う必要がある．レジスタ値の退避・復帰を行う命令列は他のケースでも使用するので，それぞれテンプレート化して「アドレス$\mathtt{\$sp}+n$にレジスタ$r$の内容を退避する命令列$\mathit{Save}_n(r)$」と「アドレス$\mathtt{\$sp}+n$に退避したレジスタ$r$の内容を復帰する命令列$\mathit{Restore}_n(r)$」として定義しておく（後述．）$\mathit{Save}$と$\mathit{Restore}$を使うと，関数呼び出し前に実行されるべき命令列は以下の通りとなる．
  - レジスタ$\mathtt{\$a0}$をメモリ上のアドレス$\mathtt{\$sp}+n+4$に退避 ($\mathit{Save}_{n+4}(\mathtt{\$a0})$) する．$\mathtt{\$a0}$は今から行う関数呼び出しのための実引数で上書きされるからである．
  - $\mathit{oprd}_1$に格納されている実引数を$\mathtt{\$a0}$にロードする．
  - $\mathit{oprd}_f$に格納されているラベル (=コード上のアドレス) を$\mathtt{\$t0}$にロードする．
  - $\mathtt{jalr}$命令を使って$\mathtt{\$t0}$に格納されているラベルにジャンプする．$\mathtt{jalr}$命令の第一引数$\mathtt{\$ra}$には，ジャンプ先からリターンするときに帰ってくるべきコード上のアドレス (=この命令の次の行) がセットされる．（なので，$\mathtt{\$ra}$はこの命令の実行前にどこかに退避されていなければならないが，これは関数定義のアセンブリ生成のところで説明する．）この次の行からは，この後呼び出された関数が実行されリターンした後に実行されるべき命令列が書いてある．
  - レジスタ $\mathtt{\$v0}$ に格納されているはずの（関数呼び出し規約を参照のこと）リターンされた値を$\mathbf{local}(\mathit{ofs})$，すなわち$\mathtt{\$sp}+\mathit{ofs}$に$\mathtt{sw}$命令を使ってストアする．
  - $\mathtt{\$sp}+n+4$に呼び出し前に退避しておいたレジスタ$\mathtt{\$a0}$の内容を復帰させる ($\mathit{Restore}_{n+4}(\mathtt{\$a0})$)．
以上の命令列が実際に正しく関数呼び出しを実行することを確認するためには，関数呼出し時の命令のみではなく，リターン命令 ($\mathcal{G}_n(\mathbf{return} \; \mathit{oprd}$) や関数定義側でどのような命令列が生成されるかも確認する必要がある．前者についてはすぐ，後者については後で$\mathcal{G}(d)$の定義を説明する際にそれぞれ説明する．
- $\mathbf{return} \; \mathit{oprd}$: $\mathit{oprd}$に格納されている値を呼び出し側に返さなければならない．関数呼び出し規約によれば，関数がリターンする前には以下の処理を行う必要がある: (1) 返り値をレジスタ$\mathtt{\$v0}$にロード, (2) 関数の先頭でフレーム内に退避しておいた$\mathtt{\$ra}$の値を復帰，(3) $\mathtt{\$sp}$レジスタの値を先頭で下げた分だけ上げる (すなわち，現在のフレームに使っていたスタック上の領域を解放する), (4) $\mathtt{jr}$命令を用いて$\mathtt{\$ra}$に格納されたアドレスにリターンする．具体的には以下の命令列が生成される:
  - $\mathit{oprd}$に格納されている値を返り値を格納すべきレジスタ ($\mathtt{\$v0}$) にロード ($\mathcal{G}_{\mathtt{\$v0}}(\mathit{oprd})$) する．
  - $\mathtt{\$ra}$の値の復帰とフレームの解放を行う．$\mathit{Epilogue}(n)$でこの処理を行う命令を生成している．（定義は後述）$\mathit{Epilogue}(n)$はローカルな記憶領域のサイズが$n$のフレームを持つ関数呼び出しのリターン前の処理を行う命令列で，退避しておいた$\mathtt{\$ra}$の復帰$\mathit{Restore}_{n+8}(\mathtt{\$ra})$と，$\mathtt{\$sp}$の値の更新を行う．
  - $\mathtt{jr}$命令で復帰した$\mathtt{\$ra}$にリターンする．

上述の$\mathit{Save}$と$\mathit{Restore}$は以下のように定義すればよい．

$$
\begin{array}{l}
      \begin{array}{rcl}
        \mathit{Save}_n(r) &=&
        \begin{array}[t]{l}
          \mathtt{sw} \quad r,n(\mathtt{\$sp})
        \end{array}\\
      \end{array}\\
      \begin{array}{rcl}
        \mathit{Restore}_n(r) &=&
        \begin{array}[t]{l}
          \texttt{lw} \quad r,n(\mathtt{\$sp})
        \end{array}\\
      \end{array}
\end{array}
$$

また，$\mathit{Epilogue}$の定義は以下の通りとなる．

$$
      \begin{array}{rcl}
        \mathit{Epilogue}(n) &=&
        \begin{array}[t]{l}
          \mathit{Restore}_{n+8}(\mathtt{\$ra})\\
          \mathtt{addiu} \quad \mathtt{\$sp},\mathtt{\$sp},n+8\\
        \end{array}\\
      \end{array}
$$

### 関数定義の変換

関数定義

$$
  d := 
  \left(\begin{array}{l}
    l:\\
    \; i_1\\
    \; \dots\\
    \; i_m\\
  \end{array}, 
  n\right)
$$

に対応する命令列$\mathcal{G}(d)$は以下のとおりとなる．

$$
        \begin{array}[t]{l}
          l\mathtt{:}\\
          \; \mathit{Prologue}(n)\\
          \; \mathcal{G}_{n}(i_1)\\
          \; \dots\\
          \; \mathcal{G}_{n}(i_m)\\
        \end{array}
$$

定義を以下に説明する．
- この関数のラベルを生成する ($l\mathtt{:}$)．
- 関数本体の先頭で行わなければならない処理を行う命令列を生成する．関数呼び出し規約によれば以下の処理を行う必要がある:
  - レジスタ$\mathtt{\$sp}$の値を更新して今から使うフレームを確保する．
  - レジスタ$\mathtt{\$ra}$の値をフレーム内の所定の位置に退避する．
以上の処理を行うための命令列を$\mathit{Prologue}(n)$として生成している．（定義は後述．）ここで$n$はこの関数内で使用する局所変数のための記憶領域のサイズである．$\mathit{Prologue}(n)$は初めにフレームのサイズ分$\mathtt{\$sp}$の値を$\mathtt{addiu}$命令を用いて減らす．フレームのサイズは，(局所変数用領域)+($\mathtt{\$ra}$退避先用の領域4バイト)+($\mathtt{\$a0}$退避先用の領域4バイト)なので$n+8$である．その後，$\mathtt{\$ra}$をフレーム内の所定の場所に退避している．

$\mathit{Prologue}$の定義は以下の通りである．

$$
      \begin{array}{rcl}
        \mathit{Prologue}(n) &=&
        \begin{array}[t]{l}
          \mathtt{addiu} \quad \mathtt{\$sp},\mathtt{\$sp},-n-8\\
          \mathit{Save}_{n+8}(\mathtt{\$ra})\\
        \end{array}\\
      \end{array}
$$

### プログラムの変換

最後に，プログラム

$$
\left(
  \begin{array}{l}
    d_1\\
    \dots\\
    d_m\\
    \mathit{main}:\\
    \; i_1\\
    \; \dots\\
    \; i_n\\
  \end{array},
  k
\right)
$$

に対応するアセンブリは以下の通りとなる．

$$
        \begin{array}[t]{l}
          \mathtt{.text}\\
          \mathtt{.globl\ main}\\
          \mathcal{G}(d_1)\\
          \dots\\
          \mathcal{G}(d_m)\\
          \mathtt{main:}\\
          \; \mathit{Prologue}(k)\\
          \; \mathcal{G}_k(i_1)\\
          \; \dots\\
          \; \mathcal{G}_k(i_n)\\
        \end{array}\\
$$


まず先頭で，以降にかかれている情報がプログラムである旨を示す$\mathtt{.text}$ディレクティブを生成している．その次の行には，アセンブリ中の$\mathtt{main}$というラベル名がグローバルなラベル，すなわち外部から見える名前であることが宣言されている．その後$d_1$から$d_m$までのアセンブリを順番に生成した後に，$\mathtt{main:}$に続いて，メインのプログラムを実行するためのフレームの確保を$\mathit{Prologue}(k)$で行い ($k$はフレームのサイズ)，命令列$i_1 \dots i_n$に対応するアセンブリを生成する．
