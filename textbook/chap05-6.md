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

TODO: ここから

なお，`sp`レジスタ（スタックポインタ）は，常にスタック最上部（フレームの一番下）を指すようにする．したがって，$i$番目 $(1 \le i \le N)$ の局所変数が格納されている領域はアドレス`$sp + 4i`となる．また，`saved a0` のアドレスは`$sp + 4N + 4`，リターンアドレスのアドレスは`$sp + 4N + 8`となる．

以下は，上記のスタックレイアウトに基づいて関数呼出しを行う手順の概要である（詳細な手順については次節を参照）．
- 呼出し側は，`a0`レジスタの値を（自身の）`saved a0` に退避してから，関数呼出しの実引数を`a0`レジスタにセットする．
- `jal`あるいは`jalr`命令によって呼び出される関数の先頭へジャンプする．呼出し側の次の命令のアドレスは`ra`レジスタにセットされる．
-（以下，呼び出された関数側で実行）`sp`レジスタを必要なだけ下げる．
- `ra`レジスタに入っているリターンアドレスを，スタックの所定の位置に退避する．
- 関数本体を実行し，求まった返り値を`v0`レジスタにセットする．
- スタック中のリターンアドレスをレジスタに戻す． TODO: ここから
- 
- {enum:sp}で下げたのと同じ分だけ\verb|sp|レジスタを上げるこ
  とで，スタックからフレームを取り除く．
\item \verb|jr|命令によって\ref{enum:ra}で取り出したリターンアドレスへ
  リターンする．
\item （呼出し側で実行）\verb|v0|レジスタから返り値を取り出し，さらに，
  退避しておいたsaved a0を\verb|a0|レジスタに戻す．
\end{enumerate}


最後に，以下の簡単なOCamlコード：
%
#{&}
\sf
let rec f a = g (a+1)
and g b = let x = b + b in
          let y = x * x in
          let z = y - 1 in
            z
in f 0
#{@}
%
の実行中，関数\verb|f|から関数\verb|g|を呼び出す前後のスタックの状態を
図\ref{fig:stack_layout}に示す．

\begin{figure}
\footnotesize
\begin{boxedminipage}{\textwidth}
\begin{center}
  \begin{minipage}{0.32\textwidth}
    \begin{center}
\begin{verbatim}
      +-------------+
   |  | saved a0: - |
   |  |   ...       |
   V  | [f's frame] |
      |   ...       |<- $sp
      +-------------+







         $a0 = 0

\end{verbatim}
      \medskip
      (a) 関数\verb|g|を呼び出す直前
    \end{center}
  \end{minipage}
  \begin{minipage}{0.32\textwidth}
    \begin{center}
\begin{verbatim}
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

\end{verbatim}
      \medskip
      (b) 関数\verb|g|を呼び出した直後
    \end{center}
  \end{minipage}
  \begin{minipage}{0.32\textwidth}
    \begin{center}
\begin{verbatim}
      +-------------+
   |  | saved a0: 0 |
   |  |   ...       |
   V  | [f's frame] |
      |   ...       |<- $sp
      +-------------+
  
  
  

  
  

         $a0 = 0
         $v0 = 3
\end{verbatim}
      \medskip
      (c) 関数\verb|g|からのリターン直後
    \end{center}
  \end{minipage}
\end{center}
\end{boxedminipage}
\caption{\miniML{4}のスタックレイアウト}
\label{fig:stack_layout}
\end{figure}


\begin{quotation}
    \noindent\textbf{現実の呼出し規約に関する余談}\\[2mm]
    一般のプログラミング言語では，多引数関数を定義できたり，引数の数が
    固定ではない（可変長引数と呼ばれる）関数を定義できたりする．また，
    関数本体の実行中に使用するメモリサイズを正確に求めることが難しいこ
    ともある（たとえば，スタック上に任意サイズのメモリ領域を確保でき
    るC言語の\verb|alloca関数|を使用した場合など）．そのような場合，物
    理レジスタに収まりきらない引数をスタックに置く必要がある．それに加
    え，実行中に位置が一定ではない\verb|sp|レジスタからの相対アドレスを
    用いてスタック中のパラメータおよび局所変数へアクセスしようとすると，
    コンパイル時に求める必要のある相対アドレスの計算が複雑になる．

    そこで，現実のコンパイラにおいては，\verb|sp|レジスタとは別に，関数
    フレームの\verb|sp|とは反対側（典型的には\verb|ra|の入っているあた
    り）を常に指し続ける\verb|fp|レジスタを別に用意しておき，パラメータ
    や局所変数へのアクセスには\verb|fp|レジスタからの相対アドレスを用い
    るのが一般的である．ただし，リターンアドレスと同様に，呼出し側
    の\verb|fp|レジスタの値もスタック中に退避する手間がさらに必要となる．

%    \miniML{4}言語には上記のような複雑な機能は含まれていないた
%    め，\verb|fp|レジスタは使用せず，\verb|sp|レジスタからの相対アドレ
%    スによるアクセスコードを生成することにより，呼出し規約を少し単純化
%    している．
\end{quotation}


\subsection{アセンブリ生成}

\begin{figure}
  \footnotesize
  \begin{flushleft}
    \begin{boxedminipage}{\textwidth}
      （$\sem{\OP}$は$\VMLANG$の$\OP$に対応するMIPSの命令，$\sem{l}$は
        ラベル名$l$をMIPSアセンブリ内のラベルとして解釈できるようにし
        た表現である．ただし，$\sem{l_{\mathit{main}}} =
        \mathtt{main}$とする．）
      
      \fbox{Definition of $\CODEGEN_{r}(\operand)$}
      \[
      \begin{array}{rcl}
        \CODEGEN_{r}(\PARAM(1)) &=&
        \begin{array}[t]{l}
          \MV \quad r,\PARAMREG\\
        \end{array}\\
        \CODEGEN_{r}(\mathbf{local}(n)) &=&
        \begin{array}[t]{l}
          \LW \quad r,n(\SP)\\
        \end{array}\\
        \CODEGEN_{r}(\LABELIMM(l)) &=&
        \begin{array}[t]{l}
          \LA \quad r,\sem{l}\\
        \end{array}\\
        \CODEGEN_{r}(\IMM(n)) &=&
        \begin{array}[t]{l}
          \LI \quad r,n\\
        \end{array}\\
      \end{array}
      \]

      \fbox{Definition of $\CODEGEN_{n}(i)$}\\
      \[
      \begin{array}{rcl}
        \CODEGEN_{n}(\MOVE{\mathbf{local}(\offset)}{\operand}) &=&
        \begin{array}[t]{l}
          \CODEGEN_{\TMPREGONE}(\operand)\\
          \ST \quad \TMPREGONE, \offset(\SP)\\
        \end{array}\\
        \CODEGEN_{n}(\BINOP{\mathbf{local}(\offset)}{\OP}{\operand_1,\operand_2}) &=&
        \begin{array}[t]{l}
          \CODEGEN_{\TMPREGONE}(\operand_1)\\
          \CODEGEN_{\TMPREGTWO}(\operand_2)\\
          \sem{\OP} \quad \TMPREGONE, \TMPREGONE, \TMPREGTWO\\
          \ST \quad \TMPREGONE,\offset(\SP)\\
        \end{array}\\
        \CODEGEN_{n}(\LABEL{l})) &=&
        \begin{array}[t]{l}
          \sem{l}\mathtt{{:}}
        \end{array}\\
        \CODEGEN_{n}(\BRIF{\operand}{l}) &=&
        \begin{array}[t]{l}
          \CODEGEN_{\TMPREGONE}(\operand)\\
          \BGTZ \quad \TMPREGONE,\sem{l}\\
        \end{array}\\
        \CODEGEN_{n}(\GOTO{l}) &=&
        \begin{array}[t]{l}
          \JUMP \quad \sem{l}
        \end{array}\\
        \CODEGEN_{n}(\CALL{\mathbf{local}(\offset)}{\operand_f(\operand_1)}) &=&
        \begin{array}[t]{l}
          \SAVE_{n+4}(\PARAMREG)\\
          \CODEGEN_{\PARAMREG}(\operand_1)\\
          \CODEGEN_{\TMPREGONE}(\operand_f)\\
          \JALR \quad \RA,\TMPREGONE\\
          \ST \quad \RETREG,\offset(\SP)\\
          \RESTORE_{n+4}(\PARAMREG)\\
        \end{array}\\
        \CODEGEN_{n}(\RETURN(\operand)) &=&
        \begin{array}[t]{l}
          \CODEGEN_{\RETREG}(\operand)\\
          \EPILOGUE(n)\\
          \JR \quad \RA\\
        \end{array}\\
      \end{array}
      \]
      
      \fbox{Definition of $\CODEGEN(d)$}
      \[
      \begin{array}{rcl}
        \CODEGEN((l \mid i_1 \dots i_m \mid n)) &=&
        \begin{array}[t]{l}
          \sem{l}\mathtt{:}\\
          \PROLOGUE(n)\\
          \CODEGEN_{n}(i_1)\\
          \dots\\
          \CODEGEN_{n}(i_m)\\
          % \EPILOGUE(n)\\
        \end{array}\\
      \end{array}
      \]

      \fbox{Definition of $\CODEGEN(P)$}
      \[
      \begin{array}{rcl}
        \CODEGEN((d_1 \dots d_m \mid i_1 \dots i_n \mid k)) &=&
        \begin{array}[t]{l}
          \mathtt{.text}\\
          \mathtt{.globl\ main}\\
          \CODEGEN(d_1)\\
          \dots\\
          \CODEGEN(d_m)\\
          \sem{l_{\mathit{main}}}\mathtt{:}\\
          \PROLOGUE(k)\\
          \CODEGEN_k(i_1)\\
          \dots\\
          \CODEGEN_k(i_n)\\
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
      （$\sem{\OP}$は$\VMLANG$の$\OP$に対応するMIPSの命令名である．）
      
      \fbox{Definition of $\PROLOGUE(n)$}
      
      \[
      \begin{array}{rcl}
        \PROLOGUE(n) &=&
        \begin{array}[t]{l}
          \ADDIU \quad \SP,\SP,-n-8\\
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
          \ADDIU \quad \SP,\SP,n+8\\
          % \JR \quad \RA\\
        \end{array}\\
      \end{array}
      \]

      \fbox{Definition of $\SAVE_n(r)$}

      \[
      \begin{array}{rcl}
        \SAVE_n(r) &=&
        \begin{array}[t]{l}
          \ST \quad r,n(\SP)
        \end{array}\\
      \end{array}
      \]

      \fbox{Definition of $\RESTORE_n(r)$}

      \[
      \begin{array}{rcl}
        \RESTORE_n(r) &=&
        \begin{array}[t]{l}
          \LW \quad r,n(\SP)
        \end{array}\\
      \end{array}
      \]

    \end{boxedminipage}
  \end{flushleft}
  \caption{アセンブリ生成用補助関数の定義．}
  \label{fig:auxiliary}
\end{figure}

%% \begin{figure}
%%   \footnotesize
%%   \begin{flushleft}
%%     \begin{boxedminipage}{\textwidth}
%%       （$\sem{\OP}$は$\VMLANG$の$\OP$に対応するMIPSの命令である．）
      
%%       \fbox{Definition of $\CODEGEN_{r}(\operand)$}
%%       \[
%%       \begin{array}{rcl}
%%         \CODEGEN_{r}(\PARAM(1)) &=&
%%         \begin{array}[t]{l}
%%           \MV \quad r,\PARAMREG\\
%%         \end{array}\\
%%         \CODEGEN_{r}(\mathbf{local}(n)) &=&
%%         \begin{array}[t]{l}
%%           \LW \quad r,n(\SP)\\
%%         \end{array}\\
%%         \CODEGEN_{r}(\LABELIMM(l)) &=&
%%         \begin{array}[t]{l}
%%           \LA \quad r,l\\
%%         \end{array}\\
%%         \CODEGEN_{r}(\IMM(n)) &=&
%%         \begin{array}[t]{l}
%%           \LI \quad r,n\\
%%         \end{array}\\
%%       \end{array}
%%       \]

%%       \fbox{Definition of $\CODEGEN_{n}(i)$}\\
%%       \[
%%       \begin{array}{rcl}
%%         \CODEGEN_{n}(\MOVE{\mathbf{local}(\offset)}{\operand}) &=&
%%         \begin{array}[t]{l}
%%           \CODEGEN_{\TMPREGONE}(\operand)\\
%%           \ST \quad \TMPREGONE, \offset(\SP)\\
%%         \end{array}\\
%%         \CODEGEN_{n}(\BINOP{\mathbf{local}(\offset)}{\OP}{\operand_1,\operand_2}) &=&
%%         \begin{array}[t]{l}
%%           \CODEGEN_{\TMPREGONE}(\operand_1)\\
%%           \CODEGEN_{\TMPREGTWO}(\operand_2)\\
%%           \sem{\OP} \quad \TMPREGONE, \TMPREGONE, \TMPREGTWO\\
%%           \ST \quad \offset(\SP), \TMPREGONE\\
%%         \end{array}\\
%%         \CODEGEN_{n}(\LABEL{l})) &=&
%%         \begin{array}[t]{l}
%%           l:
%%         \end{array}\\
%%         \CODEGEN_{n}(\BRIF{\operand}{l}) &=&
%%         \begin{array}[t]{l}
%%           \CODEGEN_{\TMPREGONE}(\operand)\\
%%           \BGTZ \quad \TMPREGONE,l\\
%%         \end{array}\\
%%         \CODEGEN_{n}(\GOTO{l}) &=&
%%         \begin{array}[t]{l}
%%           \JUMP \quad l
%%         \end{array}\\
%%         \CODEGEN_{n}(\CALL{\mathbf{local}(\offset)}{\operand_f(\operand_1)}) &=&
%%         \begin{array}[t]{l}
%%           \SAVE_{4n+4}(\PARAMREG)\\
%%           \SAVE_{4n+8}(\RA)\\
%%           \CODEGEN_{\PARAMREG}(\operand_1)\\
%%           \JR \quad \operand_f\\
%%           \ST \quad \offset(\SP),\RETREG\\
%%           \RESTORE_{4n+8}(\RA)\\
%%           \RESTORE_{4n+4}(\PARAMREG)\\
%%         \end{array}\\
%%         \CODEGEN_{n}(\RETURN(\operand)) &=&
%%         \begin{array}[t]{l}
%%           \CODEGEN_{\RETREG}(\operand)\\
%%           \JR \quad \RA\\
%%         \end{array}\\
%%       \end{array}
%%       \]
      
%%       \fbox{Definition of $\CODEGEN(d)$}
%%       \[
%%       \begin{array}{rcl}
%%         \CODEGEN((i_1 \dots i_m \mid n)) &=&
%%         \begin{array}[t]{l}
%%           \PROLOGUE(n)\\
%%           \CODEGEN_{n}(i_1)\\
%%           \dots\\
%%           \CODEGEN_{n}(i_m)\\
%%           \EPILOGUE(n)\\
%%         \end{array}\\
%%       \end{array}
%%       \]

%%       \fbox{Definition of $\CODEGEN(P)$}
%%       \[
%%       \begin{array}{rcl}
%%         \CODEGEN((d_1 \dots d_m \mid i_1 \dots i_n \mid k)) &=&
%%         \begin{array}[t]{l}
%%           \CODEGEN(d_1)\\
%%           \dots\\
%%           \CODEGEN(d_m)\\
%%           \PROLOGUE(k)\\
%%           \CODEGEN_k(i_1)\\
%%           \dots\\
%%           \CODEGEN_k(i_n)\\
%%           \EPILOGUE(k)\\
%%         \end{array}\\
%%       \end{array}
%%       \]
%%     \end{boxedminipage}
%%   \end{flushleft}
%%   \caption{アセンブリ生成の定義．}
%%   \label{fig:codegen}
%% \end{figure}

以上を踏まえて，$\VMLANG$のプログラムをMIPSアセンブリに変換する関数
$\CODEGEN$の定義を図~\ref{fig:codegen}に示す．なお，以下の説明ではMIPS
アセンブリ中の命令について逐一説明はしないので，必要であればリファレン
ス~\cite{}を参照されたい．

% \AI{ふたつめの図冒頭の「（$\sem{\OP}$は$\VMLANG$の$\OP$に対応するMIPSの命令である．）」は必要？}

オペランドの変換は$\CODEGEN_{r}(\operand)$で行う．この変換では
「$\operand$に格納されている値をレジスタ$r$にロードする」MIPSアセンブ
リが生成される．各ケースの説明は以下の通りである．
\begin{description}
\item[$\CODEGEN_{r}(\PARAM(1))$]: $\PARAM(1)$（関数の第一引数）をレジ
  スタ$r$にロードする．現在の$\VMLANG$では一引数関数のみが定義できるた
  め$\PARAM(1)$についてのみ定義されている．関数の引数は関数呼び出し規
  約からレジスタ$\PARAMREG$に格納されているので，この内容を$r$にロード
  するために$\MV$命令を用いている．
\item[$\CODEGEN_{r}(\mathbf{local}(n))$]: $\mathbf{local}(n)$に格納されている値をレジ
  スタ$r$にロードする．$\mathbf{local}(n)$は関数呼び出し規約から$n(\SP)$に格
  納されているので，これをレジスタ$r$にロードするために$\LW$命令を用い
  る．
\item[$\CODEGEN_{r}(\LABELIMM(l))$]: コード中のラベル$l$のアドレスを
  $r$にロードする．\footnote{このようにレジスタにコード中のアドレスを
  ロードすることで，コード中の「場所」を値として保持することが可能とな
  る．これは高階関数の実装で必要になる．}このために$\LA$命令を用いてい
  る．$\sem{l}$はラベル$l$をMIPS内で解釈できる記号に変換したものである．
\item[$\CODEGEN_{r}(\IMM(n))$]: 整数定数$n$をレジスタ$r$にロードする．
  これは$\LI$命令を用いて実装することができる．
\end{description}

命令の変換を行う関数$\CODEGEN_{n}(i)$は，$\VMLANG$の命令$i$を，局所変数
用に$n$バイトを使う関数の内部にあると仮定して実行するMIPSの命令列を生成
する．この$n$はフレーム内に格納されている値にアクセスする際に，そのアド
レスの$\SP$からのオフセットを計算するために用いられる．各ケースの説明は
以下の通りである．
\begin{description}
\item[$\CODEGEN_{n}(\MOVE{\mathbf{local}(\offset)}{\operand})$]: この命令は
  「$\operand$に格納されている値を$\mathbf{local}(\offset)$に格納する」ように
  動作する．そのためにまず$\operand$の値を求め，一時レジスタ
  $\TMPREGONE$に格納する命令を生成し
  （$\CODEGEN_{\TMPREGONE}(\operand)$）その後$\TMPREGONE$に格納されて
  いるアドレスからレジスタ$r$に値をロードする命令$\ST \quad
  \TMPREGONE, \offset(\SP)$を生成する．
\item[$\BINOP{\mathbf{local}(\offset)}{\OP}{\operand_1,\operand_2}$]:
  $\operand_1$に格納されている値をレジスタ$\TMPREGONE$に
  （$\CODEGEN_{\TMPREGONE}(\operand_1)$），$\operand_2$に格納されてい
  る値をレジスタ$\TMPREGTWO$に（$\CODEGEN_{\TMPREGONE}(\operand_1)$）
  それぞれロードする．その上で，レジスタ$\TMPREGONE$の値とレジスタ
  $\TMPREGTWO$の値を引数として演算子$\OP$によって計算し，その結果を
  $\TMPREGONE$にロード（$\sem{\OP} \quad \TMPREGONE, \TMPREGONE,
    \TMPREGTWO$）する．定義を簡潔にするために，演算子$\OP$に対応する
  MIPSの命令を$\sem{\OP}$で表し，具体的に使わなければならない命令を
  $\sem{-}$の定義の中に押し込めている．（例えば
    $\sem{{+}}=\mathtt{addu}, \sem{{-}}=\mathtt{mulou}$とすればよい．）
  最後にレジスタ$\TMPREGONE$の値を$\mathbf{local}(\offset)$にストア（$\ST
    \quad \TMPREGONE,\offset(\SP)$）している．$\offset$バイト目のロー
  カル変数のアドレスが$\SP+\offset$であることに注意せよ．
\item[$\LABEL{l}$]: ラベル$\sem{l}$を生成（$\sem{l}\mathtt{{:}}$）して
  いる．ここで$\sem{l}$はラベル$l$をMIPSアセンブリ内でラベルとして解釈
  できる識別子に変換したものである．この変換は一対一対応でさえあればど
  のように定義しても良いが，メインのプログラムを表すラベル
  $l_{\mathit{main}}$は，MIPSアセンブリ内のエントリポイント（プログラ
    ムの実行時に最初に制御が移される場所）を表す$\mathtt{main}$という
  ラベル名に変換する必要がある．
\item[$\CODEGEN_{n}(\BRIF{\operand}{l})$]: まず$\operand$に格納されて
  いる値をレジスタ$\TMPREGONE$に格納する．その上で，レジスタ
  $\TMPREGONE$が$\TRUE$を表す非ゼロ値であれば$\sem{l}$にジャンプ
  （$\BGTZ \quad \TMPREGONE,\sem{l}$）する．
\item[$\CODEGEN_{n}(\GOTO{l})$]: 無条件でラベル$\sem{l}$にジャンプ
  （$\JUMP \quad \sem{l}$）する．
\item[$\CODEGEN_{n}(\CALL{\mathbf{local}(\offset)}{\operand_f(\operand_1)})$]:
  関数呼び出しを行う際には，関数呼び出し規約に従ってレジスタの内容を退
  避・復帰したり，引数をセットしたり，返り値を取得したりしなければなら
  ない．今回のコンパイラにおいては，関数の呼び出し側では，
  \pageref{fig:callingConvention}ページで説明した通り，(1) レジスタ
  \verb|a0|の値の退避，(2) レジスタ\verb|v0|に格納されている返り値の取
  得，(3) 退避しておいたレジスタ\verb|a0|の値の復帰を行う必要がある．
  レジスタ値の退避・復帰を行う命令列は他のケースでも使用するので，それ
  ぞれテンプレ化して図~\ref{fig:auxiliary}に「アドレス$\SP+n$にレジス
    タ$r$の内容を退避する命令列$\SAVE_n(r)$」と「アドレス$\SP+n$に退避
    したレジスタ$r$の内容を復帰する命令列$\RESTORE_n(r)$」として定義し
  てある．$\SAVE$と$\RESTORE$を使うと，関数呼び出し前に実行されるべき
  命令列は以下の通りとなる．
  \begin{enumerate}
  \item レジスタ$\PARAMREG$をメモリ上のアドレス$\SP+n+4$に退避
    ($\SAVE_{n+4}(\PARAMREG)$) する．$\PARAMREG$は今から行う関数呼び出
    しのための実引数で上書きされるからである．
  \item $\operand_1$に格納されている実引数を$\PARAMREG$にロードする．
  \item $\operand_f$に格納されているラベル (=コード上のアドレス) を
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
    $\SP+\offset$に$\ST$命令を使ってストアする．
  \item $\SP+n+4$に呼び出し前に退避しておいたレジスタ$\PARAMREG$の内容
    を復帰させる ($\RESTORE_{n+4}(\PARAMREG)$)．
  \end{enumerate}
  以上の命令列が実際に正しく関数呼び出しを実行することを確認するために
  は，関数呼出し時の命令のみではなく，リターン命令
  ($\CODEGEN_n(\RETURN(\operand))$) や関数定義側でどのような命令列が生
  成されるかも確認することがある．前者についてはすぐ，後者については後
  で$\CODEGEN(d)$の定義を説明する際にそれぞれ説明する．
\item[$\RETURN(\operand)$]: $\operand$に格納されている値を呼び出し側に
  返さなければならない．関数呼び出し規約によれば，関数がリターンする前
  には以下の処理を行う必要がある: (1) 返り値をレジスタ$\RETREG$にロー
  ド, (2) 関数の先頭でフレーム内に退避しておいた$\RA$の値を復帰，(3)
  $\SP$レジスタの値を先頭で下げた分だけ上げる (すなわち，現在のフレー
  ムに使っていたスタック上の領域を解放する), (4) $\JR$命令を用いて
  $\RA$に格納されたアドレスにリターンする．具体的には以下の命令列が生
  成される:
  \begin{enumerate}
  \item $\operand$に格納されている値を返り値を格納すべきレジスタ
    ($\RETREG$) にロード ($\CODEGEN_{\RETREG}(\operand)$) する．
  \item $\RA$の値の復帰とフレームの解放を行う．定義中では
    $\EPILOGUE(n)$でこの処理を行う命令を生成している．$\EPILOGUE(n)$は
    ローカルな記憶領域のサイズが$n$のフレームを持つ関数呼び出しのリター
    ン前の処理を行う命令列で，退避しておいた$\RA$の復帰
    $\RESTORE_{n+8}(\RA)$と，$\SP$の値の更新を行う．
  \item $\JR$命令で復帰した$\RA$にリターンする．
  \end{enumerate}
\end{description}

関数定義$(l \mid i_1 \dots i_m \mid n)$に対応する命令列$\CODEGEN((l
\mid i_1 \dots i_m \mid n))$は以下のアセンブリを生成する．
\begin{enumerate}
\item この関数のラベルを生成する ($\sem{l}\mathtt{:}$)．
\item 関数本体の先頭で行わなければならない処理を行う命令列を生成する．
  関数呼び出し規約によれば以下の処理を行う必要がある:
  \begin{enumerate}
  \item レジスタ$\SP$の値を更新して今から使うフレームを確保する．
  \item レジスタ$\RA$の値をフレーム内の所定の位置に退避する．
  \end{enumerate}
  以上の処理を行うための命令列を$\PROLOGUE(n)$として
  図~\ref{fig:auxiliary}に定義している．ここで$n$はこの関数内で使用す
  る局所変数のための記憶領域のサイズである．$\PROLOGUE(n)$は初めにフレー
  ムのサイズ分$\SP$の値を$\ADDIU$命令を用いて減らす．フレームのサイズ
  は，(局所変数用領域)+($\RA$退避先用の領域4バイト)+($\PARAMREG$退避先
  用の領域4バイト)なので$n+8$である．その後，$\RA$をフレーム内の所定の
  場所に退避している．
\end{enumerate}

最後に，プログラム$(d_1 \dots d_m \mid i_1 \dots i_n \mid k)$のアセン
ブリ生成の定義を説明しよう．まず先頭で，以降にかかれている情報がプログ
ラムである旨を示す$\mathtt{.text}$ディレクティブを生成している．その次
の行には，アセンブリ中の$\mathtt{main}$というラベル名がグローバルなラ
ベル，すなわち外部から見える名前であることが宣言されている．その後
$d_1$から$d_m$までのアセンブリを順番に生成した後に，
$\sem{l_{\mathit{main}}}\mathtt{:}$に続いて，メインのプログラムを実行
するためのフレームの確保を$\PROLOGUE(k)$で行い ($k$はフレームのサイズ)，
命令列$i_1 \dots i_n$に対応するアセンブリを生成する．
