{% include head.html %}

# 仮想マシンコードとその生成

## 仮想マシンコード

$\mathcal{C}$から直接にアセンブリを生成することもできるのだが，アセンブリ言語は書かれている命令を順番に実行していく**命令形言語 (imperative language)**なので，関数型言語である$\mathcal{C}$とはギャップがまだ大きい．そこで，$\mathcal{C}$とアセンブリ言語の間に**仮想マシン言語**<sup>[「仮想マシン言語」という名称についての注](#vmlang)</sup>$\mathcal{V}$という中間言語を挟むことにする．<sup>[中間言語に関する注](#il)</sup>

<a name="vmlang">注：「仮想マシン言語」という名前は，命令形の中間言語の  名前として本書で便宜的に使っている名前である．このような中間言語に相当する言語は多くのコンパイラやコンパイラの教科書で用いられているが，その名前は様々である．

<a name="il">注：ソース言語とターゲット言語の間にどのような中間言語を挟むかはコンパイラを作る上で重要なデザインチョイスである．本書では$\mathcal{C}$と$\mathcal{V}$を中間言語として挟むが，より多くの中間言語を挟むコンパイラもある．


$\mathcal{V}$の定義を示す前に，$\mathcal{V}$がどんな感じの言語かを見てみよう．以下のプログラムは，言語$\mathcal{V}$で書かれた，$3$に$1$を加えるプログラムである．

$$
\begin{array}{llll}
  l_f: &&&\\
  & \mathbf{local}(4) &\leftarrow& \mathbf{param}(1)\\
  & \mathbf{local}(0) &\leftarrow& \mathit{add} \; \mathbf{local}(4), \mathbf{imm}(1)\\
  & \mathbf{return} &\quad& \mathbf{local}(0)\\
  l_{\mathit{main}}: &&&\\
  & \mathbf{local}(0) &\leftarrow& \mathbf{call} \; \mathbf{labimm}(l_f), \mathbf{imm}(3)\\
\end{array}
$$

プログラムは命令の列である．プログラム中の$l_f$や$l_{\mathit{main}}$は**ラベル (label)**と呼ばれる識別子で，プログラム中の位置を表している．ラベルは処理のジャンプ先を指定する際に用いられる．
<!-- 例えば，プログラム中の$\dots \leftarrow \mathbf{call} \; \mathbf{labimm}(l_f), \dots$命令は関数呼び出しをするために$l_f$に処理を移す命令である．-->

このプログラム中の各命令の動作を順番に見てみよう．ラベル$l_f$から始まる部分にかかれている命令は以下のとおりである．

- $\mathbf{local}(4) \leftarrow \mathbf{param}(1)$: ラベル$l_f$から始まる関数の第一引数の値を，$\mathbf{local}(4)$で指される記憶領域に格納する．アセンブリ言語において関数呼び出しを実装するには，呼び出された関数のローカルな記憶領域（この記憶領域のことを**フレーム (frame)**と呼ぶ）をどのように確保するか，その記憶領域をどのように使うか，引数や返り値をどのように受け渡しするかを決定する必要がある．これらの決まりごとを**呼び出し規約 (calling convention)**という．言語$\mathcal{V}$においては，関数に渡された引数は$\mathbf{param}(1),\mathbf{param}(2),\dots$で参照し，ローカルな変数の格納先は$\mathbf{local}(0),\mathbf{local}(4),\dots$のようにローカルな記憶領域内部の場所を表す名前を付けておくことにより，あとでアセンブリ生成を行う際に呼び出し規約を完全に決められるようにしてある．
- $\mathbf{local}(0) \leftarrow \mathit{add} \; \mathbf{local}(4),\mathbf{imm}(1)$: フレーム中で$\mathbf{local}(4)$という名前で指される領域に格納されている値（すなわち前の命令でセットされた関数の第一引数）と整数値$1$とを加算して$\mathbf{local}(0)$に格納する．$\mathbf{imm}(n)$は整数定数$n$を表すオペランドで，imm というオペランド名はアセンブリ言語で命令語中に直接現れる定数を表す**即値 (immediate)**という用語に由来する．
- $\mathbf{return} \; \mathbf{local}(0)$: $\mathbf{local}(0)$に格納されている値を関数の返り値として返す．

$l_{\mathit{main}}$はプログラムが起動されたときに実行が始まるプログラム中の箇所を指すラベルである．ここでは命令$\mathbf{local}(0) \leftarrow \mathbf{call} \; \mathbf{labimm}(l_f), \mathbf{imm}(3)$が実行される．この命令は$l_f$から始まる命令列を関数と思って引数$\mathbf{imm}(3)$で呼び出し，返り値を記憶領域$\mathbf{local}(0)$に格納する．$\mathbf{labimm}(l_f)$は，ラベル名$l_f$が表すコード上のアドレスを表す即値である．

$\mathcal{V}$は以下の BNF で定義される言語である．

$$
\begin{array}{rcl}
  \mathit{oprd} &::=& \mathbf{param}(n) \mid \mathbf{local}(\mathit{ofs}) \mid \mathbf{labimm}(l) \mid \mathbf{imm}(n)\\
  i &::=& \mathbf{local}(\mathit{ofs}) \leftarrow \mathit{oprd} \mid \mathbf{local}(\mathit{ofs}) \leftarrow \mathit{bop} \; \mathit{oprd}_1,\mathit{oprd}_2 \mid l: \mid \mathbf{if} \; \mathit{oprd} \ne 0 \; \mathbf{then} \; \mathbf{goto} \; l\\
  &\mid& \mathbf{goto} \; l \mid \mathbf{local}(\mathit{ofs}) \leftarrow \mathbf{call} \; {\mathit{oprd}_0} \; \mathit{oprd}_1,\dots,\mathit{oprd}_n \mid \mathbf{return}(\mathit{oprd})\\
  d &::=& \langle i_1 \dots i_m \mid n\rangle\\
  P &::=& \langle \{d_1 \dots d_m\} \mid i_1 \dots i_n \mid k \rangle\\
\end{array}
$$

$l$はラベル名を表すメタ変数，$\mathit{ofs}$は整数値である．プログラムは**命令 (instruction)**の列である．各命令は，命令の種類と命令の引数（**オペランド(operand)**）によってどのように動作するかが決まる．言語$\mathcal{V}$のオペランドは値の記憶領域か定数値を表す情報で，具体的には以下のいずれかである．

- $\mathbf{param}(n)$: 関数に渡された$n$番目の引数の格納場所を表す．
- $\mathbf{local}(\mathit{ofs})$: 現在のフレームのうち，「基準となるアドレス」から$\mathit{ofs}$バイト目のアドレスを表す．（後でフレームの内部構造を説明するが，そこでもう少し詳しく説明する．）
- $\mathbf{imm}(n)$: 整数定数$n$を表す．
- $\mathbf{labimm}(l)$: ラベル名$l$を表す定数を表す．関数呼び出しを行う際に使用する．

では，各命令の意味を説明しよう．以下の説明で「$\mathit{oprd}$の値」という表現を用いることがある．これは，$\mathit{oprd}$が$\mathbf{param}(n)$であれば$n$番目の引数として渡された値を，$\mathbf{local}(\mathit{ofs})$であればフレーム中の場所$\mathit{ofs}$に格納されている値を，$\mathbf{imm}(n)$であれば整数値$n$を，それぞれ表す．

- $\mathbf{local}(\mathit{ofs}) \leftarrow \mathit{oprd}$: $\mathit{oprd}$の値をフレーム中の$\mathbf{local}(\mathit{ofs})$の指す記憶領域に格納する．
- $\mathbf{local}(\mathit{ofs}) \leftarrow \mathit{bop} \; \mathit{oprd}_1,\mathit{oprd}_2$: $\mathit{oprd}_1$と$\mathit{oprd}_2$の値を${\mathit{bop}}$で計算して，フレーム中の$\mathbf{local}(\mathit{ofs})$の場所に格納する．
- $l:$: プログラム中のラベル名$l$で指される場所を表す．
- $\mathbf{if} \; \mathit{oprd} \ne 0 \; \mathbf{then} \; \mathbf{goto} \; l$: $\mathit{oprd}$の値が$0$でなければ$l$に制御を移す．そうでなければ何もしない．
- $\mathbf{goto} \; l$: $l$に制御を移す．
- $\mathbf{local}(\mathit{ofs}) \leftarrow \mathbf{call} \; \mathit{oprd} \; \mathit{oprd}_1,\dots,\mathit{oprd}_n$: $\mathit{oprd}_1,\dots,\mathit{oprd}_n$の値を引数として$\mathit{oprd}$に格納されているラベルから始まる命令列を関数として呼び出す．関数が返ったら，返り値を$\mathbf{local}(\mathit{ofs})$に格納する．
- $\mathbf{return} \; \mathit{oprd}$: $\mathit{oprd}$に格納されている値を現在実行中の関数の返り値として返す．

関数定義 $\langle i_1 \dots i_m \mid n \rangle$ は，関数のラベル名と，その関数本体の命令列と，関数内で使われるローカル変数に必要な記憶領域のサイズ$n$ からなる．この記憶領域サイズは，後のコード生成フェーズで使用される．プログラムは $\langle \{d_1 \dots d_m} \mid i_1 \dots i_n \mid k \rangle$ の形をしており，関数定義 $d_1 \dots d_m$ と，メインのプログラムに対応する命令列 $i_1 \dots i_n$ と，メインのプログラム内で使われるローカル変数のための記憶領域のサイズ $k$ からなる．

## $\mathcal{C}$の式から$\mathcal{V}$への変換

では，$\mathcal{C}$から$\mathcal{V}$への変換$\mathcal{T}$を定義しよう．**変換の定義を簡潔に保つために，変換対象の$\mathcal{C}$プログラムではすべての束縛変数が一意な名前にあらかじめ変換されているものとする．**例えば，$\mathbf{let}\ x = 1\ \mathbf{in}\ \mathbf{let}\ x = 2\ \mathbf{in}\ x$というプログラムは$\mathbf{let}\ x_1 = 1\ \mathbf{in}\ \mathbf{let}\ x_2 = 2\ \mathbf{in}\ x_2$というプログラムにあらかじめ変換がなされているものとする．実際に，先に示した変換$\mathcal{I}$はすべての束縛変数が一意な名前を持つように変換を行っている．

$\mathcal{C}$の式に対する変換$\mathcal{T}_{\delta,\mathit{tgt}}(e)$は以下のように定義される．ただし，$\delta$は識別子からオペランドへの部分関数，$\mathit{tgt}$は$\mathbf{local}(n)$の形をしたローカル領域のアドレスである．また，以下の定義中$l_1$と$l_2$はfreshなラベル名である．

$$
\begin{array}{rcl}
  \mathcal{T}_{\delta,\mathit{tgt}}(x) &=& \mathit{tgt} \leftarrow \delta(x)\\ 
  \mathcal{T}_{\delta,\mathit{tgt}}(n) &=& \mathit{tgt} \leftarrow \mathbf{imm}(n)\\
  \mathcal{T}_{\delta,\mathit{tgt}}(\mathbf{true}) &=& \mathit{tgt} \leftarrow \mathbf{imm}(1)\\
  \mathcal{T}_{\delta,\mathit{tgt}}(\mathbf{false}) &=& \mathit{tgt} \leftarrow \mathbf{imm}(0)\\
  \mathcal{T}_{\delta,\mathit{tgt}}(x_1 \; \mathit{bop} \; x_2) &=& \mathit{tgt} \leftarrow \mathit{bop} \; \delta(x_1),\delta(x_2)\\
  \mathcal{T}_{\delta,\mathit{tgt}}(\mathbf{if}\ x\ \mathbf{then}\ e_1\ \mathbf{else}\ e_2) &=&
  \begin{array}[t]{l}
    \mathbf{if} \; \delta(x) \ne 0 \; \mathbf{then} \; \mathbf{goto} \; l_1\\
    \; \mathcal{T}_{\delta,\mathit{tgt}}(e_2)\\
    \; \mathbf{goto} \; l_2\\
    l_1:\\
    \; \mathcal{T}_{\delta,\mathit{tgt}}(e_1)\\
    l_2:\\
  \end{array}\\
  \mathcal{T}_{\delta,\mathit{tgt}}(\mathbf{let}\ x = e_1\ \mathbf{in}\ e_2) &=&
    \begin{array}[t]{l}
      \mathcal{T}_{\delta,\delta(x)}(e_1)\\
      \mathcal{T}_{\delta,\mathit{tgt}}(e_2)\\
    \end{array}\\
  \mathcal{T}_{\delta,\mathit{tgt}}(x_1 \; x_2) &=& \mathit{tgt} \leftarrow \mathbf{call} \; \delta(x_1) \; \delta(x_2)\\
\end{array}
$$

式$e$の変換$\mathcal{T}_{\delta,\mathit{tgt}}(e)$は$e$の他に変数からオペランドへの部分関数$\delta$とオペランド$\mathit{tgt}$を引数として取り，「変数の記憶領域が$\delta$に書いてあると仮定して$e$を評価した結果を$\mathit{tgt}$に格納する」仮想マシンコードを生成する．各ケースの説明は以下の通りである．

- $\mathcal{T}_{\delta,\mathit{tgt}}(x)$: $x$の評価結果を$\mathit{tgt}$に格納するコードを生成する必要がある．$x$が格納されている場所は$\delta(x)$なので，$\mathit{tgt} \leftarrow \delta(x)$を生成すればよい．
- $\mathcal{T}_{\delta,\mathit{tgt}}(n)$: $n$の評価結果を$\mathit{tgt}$に格納するコードを生成するので，$\mathit{tgt} \leftarrow \mathbf{imm}(n)$ を生成すればよい．
- $\mathcal{T}_{\delta,\mathit{tgt}}(b)$ (where $b = \mathbf{true}$ or $\mathbf{false}$): $\mathbf{true}$は整数定数$1$で，$\mathbf{false}$は整数定数$0$でエンコードしていることに注意．
- $\mathcal{T}_{\delta,\mathit{tgt}}(x_1 \; \mathit{bop} \; x_2)$: $x_1$, $x_2$を格納している場所はそれぞれ$\delta(x_1)$, $\delta(x_2)$なので，これらを$\mathit{bop}$で計算して$\mathbf{local}(\mathit{tgt})$に格納するコード$\mathit{tgt} \leftarrow \mathit{bop} \; \delta(x_1),\delta(x_2)$を生成している．
- $\mathcal{T}\_{\delta,\mathit{tgt}}(\mathbf{if} \; x \; \mathbf{then} \; e_1 \; \mathbf{else} \; e_2)$: $x$の値が格納されている$\delta(x)$に非ゼロの値が入っていれば（すなわち$x$が$\mathbf{true}$であれば）$l_1$にジャンプする．もしここで値がゼロであれば（すなわち$x$が$\mathbf{false}$であれば）その後ろがそのまま実行されるので，$e_2$を評価するコード$\mathcal{T}\_{\delta,\mathit{tgt}}(e_2)$を書いておき，その後ラベル$l_1$のコードを飛び越せるように$\mathbf{goto} \; {l_2}$を書いておく．ラベル$l_1$以降には$\mathcal{T}\_{\delta,\mathit{tgt}}(e_1)$で$e_1$を評価するコードが書いてある．
- $\mathcal{T}\_{\delta,\mathit{tgt}}(\mathbf{let} \; x = e_1 \; \mathbf{in} \; e_2)$: まず初めに$e_1$を評価して$\delta(x)$に格納するコード$\mathcal{T}\_{\delta,\delta(x)}(e_1)$を置く．その後，$e_2$の評価結果を$\mathit{tgt}$に格納するコード$\mathcal{T}\_{\delta,\mathit{tgt}}(e_2)$を置く．
- $\mathcal{T}_{\delta,\mathit{tgt}}(x_1 \; x_2)$: 関数呼び出しを行い，その返り値を$\mathit{tgt}$に格納するコード$\mathit{tgt} \leftarrow \mathbf{call} \; \delta(x_1) \;\delta(x_2)$を生成する．ジャンプ先のラベルは$\delta(x_1)$に格納されている．また，$\delta(x_2)$に引数が格納されている．

## $\mathcal{C}$の関数定義から$\mathcal{V}$への変換

関数定義$\mathbf{let} \; \mathbf{rec} \; f = \mathbf{fun} \; x \rightarrow e$は，(1) 関数 $f$ に対応する命令列のの始まる場所を示すラベル，(2) 関数本体式の評価結果を$\mathbf{local}(0)$に格納する命令列，(3) $\mathbf{local}(0)$を返り値として返す命令を順番に並べた命令列に変換される．その際に，後でアセンブリに変換する際に必要になるため，関数$f$の実行に必要なローカル変数の記憶領域のサイズも計算する．

具体的には，関数定義$\mathbf{let} \; \mathbf{rec} \; f = \mathbf{fun} \; x \rightarrow e$の変換結果$\mathcal{T}_\delta(\mathbf{let}\ \mathbf{rec}\ f\ = \mathbf{fun}\ x \rightarrow e)$は
$$
  \left(
  \begin{array}{l}
    l_f:\\
    \mathcal{T}_{\delta \cup \delta_1 \cup \delta_2, \mathbf{local}(0)}(e)\\
    \mathbf{return} \; \mathbf{local}(0)\\
  \end{array},
  4n+4
  \right)
$$
と定義される．ただし，
- $\delta_1$は$\{x \mapsto \mathbf{param}(1)\}$を表す．
- $\{x_1,\dots,x_n\}$を$e$中に出現する変数として，$\delta_2$は$\{x_1 \mapsto \mathbf{local}(4), x_2 \mapsto \mathbf{local}(8), \dots, x_n \mapsto \mathbf{local}(4n)\}$である．
- また，$\delta(f)$は$\mathbf{labimm}(l_f)$であると仮定する．

この変換は，関数定義以外に$\delta$を引数にとる．$\delta$はトップレベルで定義されている（一般には複数の）関数名を受け取って，それを対応するコードが書かれているラベルオペランド$\mathbf{labimm}(l)$に写像する．変換結果は命令列とローカル変数に必要な記憶領域のサイズのペアである．生成されている命令列は，関数本体$e$の評価結果を$\mathbf{local}(0)$に格納し，その値を$\mathbf{return} \; \mathbf{local}(0)$で呼び出し元に返すコードである．変換の定義にあらわれている$\delta \cup \delta_1 \cup \delta_2$は$\delta$を以下の二つの写像で拡張したものである．

- $\delta_1$: 仮引数名$x$から$\mathbf{param}(1)$への写像．
- $\delta_2$: $e$中に現れるすべての変数からそれぞれ固有の記憶領域$\mathbf{local}(i)$への写像．（変換$\mathcal{C}$において，すべての束縛変数の名前を一意になるように付け替えたのがここで地味に効いている．）ここでは，すべての値が4バイトで表現できるものとして<sup>[必要とされる記憶領域の計算に関する注](#localsize)</sup>，各変数に4バイトの記憶領域を割り当て，$\delta_2$を$\{x_1 \mapsto \mathbf{local}(4), x_2 \mapsto \mathbf{local}(8), \dots, x_n \mapsto \mathbf{local}(4n)\}$としている．

この関数で必要とされるローカルな記憶領域のサイズは，$x_1,\dots,x_n$のための記憶領域と，返り値用の$\mathbf{local}(0)$とを合わせて$4n+4$である．

<a name="localsize">必要とされる記憶領域の計算について：ローカル変数$x_1,\dots,x_n$が束縛されている値のための記憶領域がそれぞれ4バイトという仮定は，普通は成り立たない．例えば，言語がペア型の値で拡張され，ローカル変数$x$がペア型の値に束縛されており，そのペアの要素をどちらもローカルな領域に保持しておきたい場合は，$x$に必要な記憶領域はより大きいはずである．（実際はペア等の値はヒープと呼ばれる別のメモリ領域に記憶しておき，この領域へのポインタのみをローカルな領域に保持しておくことも多い．こうすれば，ローカルな領域にはポインタを保持しておけばよい．ただし，ペアの要素にアクセスするためのメモリアクセスの回数が増えることになる．）また，これらの値の一部をレジスタに格納することにすれば，必要とされるローカルな記憶領域はより少なくて済むであろう．（ただしこの場合，使用可能なレジスタの個数は限られているので，どの値をどのレジスタに割り付けるかの解析をより真面目にやる必要がある．また，関数呼び出しの際のレジスタの退避・復帰が必要となる．）このように，どの値にどの記憶領域をどのように割り付けるかを決めるにあたっては，検討すべきことが結構多い．

## $\mathcal{C}$のプログラムから$\mathcal{V}$への変換

プログラム$\langle \{d_1,\dots,d_n\}, e \rangle$の変換結果$\mathcal{T}(\langle \{d_1,\dots,d_n\}, e \rangle)$は命令列と，ラベル名から整数への写像$F$のペアを返す．命令列部分は，各関数定義に対応する命令列を並べ，その後に$e$に対応する命令列を並べて得られる．また，写像$F(f)$は，関数$f$を実行するのに必要なローカル記憶領域のサイズである．具体的には，以下のように定義される．

$$
  \left(
  \begin{array}{l}
    I_1\\
    \dots\\
    I_k\\
    \mathit{main}:\\
    \; \mathcal{T}_{\delta \cup \delta',\mathbf{local}(0)}(e)\\
    \; \mathbf{return} \; \mathbf{local}(0)\\
  \end{array},
  \{f_1 \mapsto n_1, \dots, f_k \mapsto n_k, \mathit{main} \mapsto 4m+4\}
  \right)\\
$$

ここで，
- 各$i$について，$\mathcal{T}_\delta(d_i) = \left(I_i, n_i\right)$である．
- $\{f_1,\dots,f_n\}$は，$d_1,\dots,d_n$ で定義されている関数名である．
- $\{x_1,\dots,x_m\}$は$e$中の変数の集合である．
- $\delta$は$\{f_1 \mapsto \mathbf{labimm}(f_1), \dots, f_n \mapsto \mathbf{labimm}(f_n)\}$である．
- $\delta'$は$\{x_1 \mapsto \mathbf{local}(4), x_2 \mapsto \mathbf{local}(8), \dots, x_m \mapsto \mathbf{local}(4m)\}$である．

$\delta$は各$d_i$で定義されている関数名$f_i$からラベル名$\mathbf{labimm}(f_i)$への写像である．その後メインの式である$e$を評価するコードを生成すればよい．このコードの先頭にはラベル$\mathit{main}:$を配置している．$e$を評価する際に，$e$中の変数のための記憶領域を割り当てる必要があるが，これは上記の関数定義の仮想マシンコード生成と同じ考え方である．