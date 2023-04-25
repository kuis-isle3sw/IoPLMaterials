{% include head.html %}

# $\mathcal{C}$の最適化

この節から少し*コード最適化 (code optimization)*（略して最適化）の話をする．<sup>[1](#optimization)</sup>最適化とは，コンパイラによって生成されるコードの効率を向上させるために行う種々の解析とプログラム変換の総称である．ここでいう「効率」の意味は様々で，コードの実行時間，コードが使用するメモリ量，コード自体のサイズ等多岐に渡る．ここでは言語$\mathcal{C}$の上で簡単な最適化をやってみよう．

<a name="optimization">1</a>「最適化」という言葉は情報科学の分野では様々な意味を持つので注意が必要である．実数上の関数を与えられた制約の下で数値的な手法を用いて最小化または最大化する手法である*数値最適化 (numerical optimization)*や，離散値上の関数を与えられた制約の下で最小化または最大化する手法である*組み合わせ最適化 (combinatorial optimization)*等があるが，これらをコンパイラで行われる最適化と混同しないこと．（もちろん，組み合わせ最適化や数値最適化を用いてコンパイラでの最適化を行うことはありうる．）
	
## 無駄な束縛の除去

_無駄な束縛の除去 (elimination of redundant bindings)_ は，その後使われることがなく，除去してもプログラムの意味を変えないとわかっている束縛を除去する変換である．例えば，プログラム `let x = 3 in 4` は，`x` を `3` に束縛して `4` を返すが，束縛された `x` はその後一切使われないので，この束縛は _無駄 (redundant)_ である．これを束縛を行わない（多くの場合より効率のよい）プログラム `4` に変換するのが，無駄な束縛の除去である．

この変換は（というか，一般に多くの最適化は）何度か繰り返すことでより効率のよいプログラムを得ることが可能となる．例えば，プログラム `let x  = 3 in let y = x + 2 in 4` において，束縛変数 `x` は `y` の束縛先の計算を行う式 `x+2` で使われているので無駄ではないが，束縛変数 `y` はその後使われていないので無駄である．そこで，無駄な `y` の束縛を除去すると，このプログラムは `let x = 3 in 4` になるが，このプログラムにおいては `x` の束縛が無駄であるから，再度無駄な束縛を除去することにより，`4` を得ることができる．

無駄な束縛の除去は以下に示す変換によって定義することができる．

$$
\begin{array}{rcl}
	\mathcal{R}(x) &=& x\\
    \mathcal{R}(n) &=& n\\
    \mathcal{R}(\mathbf{true}) &=& \mathbf{true}\\
    \mathcal{R}(\mathbf{false}) &=& \mathbf{false}\\
    \mathcal{R}(x_1\ \mathit{op}\ x_2) &=& x_1\ \mathit{op}\ x_2\\
    \mathcal{R}(\mathbf{if}\ x\ \mathbf{then}\ e_1\ \mathbf{else}\ e_2) &=& \mathbf{if}\ x\ \mathbf{then}\ \mathcal{R}(e_1)\ \mathbf{else}\ \mathcal{R}(e_2)\\
    \mathcal{R}(\mathbf{let}\ x = e_1\ \mathbf{in}\ e_2) &=&
	\left\{
        \begin{array}{ll}
          \mathbf{let}\ x = \mathcal{R}(e_1)\ \mathbf{in}\ \mathcal{R}(e_2) & \mbox{(if $x \in \mathbf{FV}(e_2)$ or if a function application appears in $e_1$)}\\
          \mathcal{R}(e_2) & \mbox{(otherwise)}\\
        \end{array}
        \right.\\
    \mathcal{R}(x_1 \; x_2) &=& x_1 \; x_2\\
    \mathcal{R}(\mathbf{let}\ \mathbf{rec}\ f = \mathbf{fun}\ x \rightarrow e) &=&
    \mathbf{let}\ \mathbf{rec}\ f = \mathbf{fun}\ x \rightarrow \mathcal{R}(e)\\
    \mathcal{R}(\{d_1,\dots,d_n\},e) &=& (\{\mathcal{R}(d_1),\dots,\mathcal{R}(d_n)\},\mathcal{R}(e))\\
  \end{array}
$$


ここで$\mathbf{FV}(e)$は$e$中に現れる自由変数の集合である．この変換のキモは$\mathbf{let}\ x = e_1\ \mathbf{in}\ e_2$の$e_2$中で束縛されている変数$x$や$\mathbf{let}\ \mathbf{rec}\ f = \mathbf{fun}\ x \rightarrow e_1\ \mathbf{in}\ e_2$の$e_2$中で束縛されている変数$f$が無駄かどうかを判定する部分である．前者については$x$が$e_2$に自由変数として現れておらず，かつ$e_1$が関数適用の形をしていなければ，$x$の束縛を無駄であるとして除去する．前者の自由変数に関する条件は，$x$がその後使われないための十分条件になっている．後者の条件は$e_1$が無限ループする式だった場合にプログラムの意味を変えないための条件である．例えば，関数定義$d_1 := \mathbf{let}\ \mathbf{rec}\ f \; x = f \; x$を含むプログラム$(d_1, \mathbf{let}\ x = f\ 3 \ \mathbf{in}\ 4)$を考えよう．このプログラムは必ず無限ループする．もし後者の条件がなければ，`x` の束縛が（`x` が式 `4` に自由に現れていないために）無駄だとして除去されてしまい，$(\{d_1\}, 4)$となって，無限ループしないプログラムになってしまう．最適化はあくまでプログラムの効率を上げるために行う変換なので，プログラムの意味を変えるのはマズい．これを防ぐために，`x`の束縛先の式$e_1$に，無限ループに陥る可能性のある式である関数適用が現れている場合は，束縛を除去しないようにしている．（ちなみに，関数適用が「現れている」とは，$e_1$自体が関数適用である場合はもちろん，$e_1$が$\mathbf{if}\ x\ \mathbf{then}\ x_1\; x_2\ \mathbf{else}\ \mathbf{true}$のような式である場合も含むということである．）

<!--
\footnote{$\mathcal{C}$では，ある式の評価が無限ループに陥るためには，関数適用を行わなければならない．（多分．）}
-->

上記の「$e_1$が無限ループする可能性がある場合は `x` の束縛を無駄な束縛としない」というルールは，より一般的には「$e_1$が _副作用 (side effect)_ を持つ式であれば，$x$の束縛を無駄とはしない」ということができる．副作用が何なのかを明確に定義するのは難しいのだが，式の値を計算する「評価」という作用以外の作用（例えば無限ループ，メモリ操作，I/Oなどの計算状態を変化させる作用）のことと考えておけばよい．

### Exercise 5.1 [**]
  
上記の無駄な束縛の除去は，無駄な関数定義を除去することはできない．例えば，$d_1 := \mathbf{let}\ \mathbf{rec}\ f\ x = g\ x$で$d_2 := \mathbf{let}\ \mathbf{rec}\ g\ x = f\ x$であるとき，プログラム$(\{d_1,d_2\},3)$においてはどちらの関数定義も無駄であるから，$(\emptyset,3)$にしてしまえば良いはずである．無駄な関数定義を除去できるように$\mathcal{R}$の定義を書き換えよ．$\mathcal{R}(\{d_1,\dots,d_n\},e)$の定義を書き換えればよいが，無駄な関数定義をできるだけたくさん除去できるように（しかし無駄でない関数定義は除去しないように）定義すること．

（まだ途中）

## コピー伝播

*コピー伝播 (copy propagation)*は，$\mathbf{let}\ x = y\ \mathbf{in}\ e$を
$[y/x]e$に置き換える変換である．ただし，$[y/x]e$は$e$中の$x$を$y$に置
き換えた式を表す．これによって$x$の束縛が無くなるので，効率が良くな
ることが期待される．

以下がコピー伝播を行う変換$\mathcal{P}$である．$\delta$は識別子から定数への部分関数である．変換の途
中で式$\mathbf{let}\ x = y\ \mathbf{in}\ e$を見つけると，$\mathcal{P}$は写像$\delta$に
$x$の束縛式が$y$であることを記録して$e$を変換する．変数$x$を変換する際
には，$\delta$の定義域に$x$が含まれるかどうかを確認して，含まれている
ならば$\delta(x)$に，含まれていないならば$x$に変換する．これにより，
$\mathbf{let}\ x = y\ \mathbf{in}\ e$を$[y/x]e$に変換することができる．


$$
\begin{array}{rcl}
\mathcal{P}_\delta(x) &=&
\left\{
\begin{array}{ll}
\delta(x) & \mbox{(if $x \in \mathbf{Dom}(\delta)$)}\\
	x & \mbox{(otherwise)}\\
\end{array}
\right.\\
\mathcal{P}_\delta(n) &=& n\\
\mathcal{P}_\delta(\mathbf{true}) &=& \mathbf{true}\\
	\mathcal{P}_\delta(\mathbf{false}) &=& \mathbf{false}\\
\mathcal{P}_\delta(x_1\ \mathit{op}\ x_2) &=& \mathcal{P}_\delta(x_1)\ \mathit{op}\ \mathcal{P}_\delta(x_2)\\
	\mathcal{P}_\delta(\mathbf{if}\ x\ \mathbf{then}\ e_1\ \mathbf{else}\ e_2) &=& \mathbf{if}\ \mathcal{P}_\delta(x)\ \mathbf{then}\ \mathcal{P}_\delta(e_1)\ \mathbf{else}\ \mathcal{P}_\delta(e_2)\\
\mathcal{P}_\delta(\mathbf{let}\ x = y\ \mathbf{in}\ e) &=& \mathcal{P}_{\delta[x \mapsto y]}(e)\\
\mathcal{P}_\delta(\mathbf{let}\ x = e_1\ \mathbf{in}\ e_2) &=& \mathbf{let}\ x = \mathcal{P}_\delta(e_1)\ \mathbf{in}\ \mathcal{P}_\delta(e_2) \quad\mbox{(where $e_1$ is not a variable)}\\
\mathcal{P}_\delta(x_1 \; x_2) &=& \mathcal{P}_\delta(x_1) \; \mathcal{P}_\delta(x_2)\\
\end{array}
$$

$$
\begin{array}{rcl}
\mathcal{P}(\mathbf{let}\ \mathbf{rec}\ f\ = \mathbf{fun}\ x \rightarrow e) &=&
	\mathbf{let}\ \mathbf{rec}\ f\ = \mathbf{fun}\ x \rightarrow \mathcal{P}_\emptyset(e)\\
\end{array}
$$
	
$$
\begin{array}{rcl}
\mathcal{P}((\{d_1,\dots,d_n\},e)) &=&
(\{\mathcal{P}(d_1),\dots,\mathcal{P}(d_n)\},\mathcal{P}_\emptyset(e))\\
\end{array}
$$

### Exercise 5.2 [*]

*定数畳み込み (constant folding)*を行う変換を定義せよ．定数畳み込みとは，実行時の評価結果が分かっている値を計算してしまう変換である．例えば，$\mathbf{let}\ x = 3\ \mathbf{in}\ \mathbf{let}\ y = 4\ \mathbf{in}\ x + y$は$7$に畳み込むことができる．

### Exercise 5.3 [**]

*インライン化 (inlining)*を行う変換を定義せよ．インライン化とは関数呼び出しを呼び出されている関数の本体で置き換える変換である．例えば，$d_1 := \mathbf{let}\ \mathbf{rec}\ f = \mathbf{fun}\ x \rightarrow x + 2$であるときに，プログラム$(\{d_1\},f \; 5)$をインライン化すると$(\{d_1\}, \mathbf{let}\ t_1 = 5 + 2\ \mathbf{in} t_1)$のようになる．プログラムが再帰呼び出しを含む場合には，無制限にインライン化を行うとプログラム変換が止まらなくなるので，そのようなことが無いように何らかの制限を加える必要がある．（例えばインライン化する深さを制限する，再帰を含む場合はインライン化を行わない等．）
