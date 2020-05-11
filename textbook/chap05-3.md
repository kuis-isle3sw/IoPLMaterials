{% include head.html %}

# MiniML4- から$\mathcal{C}$への変換$\mathcal{I}$

## Overview

この節では，MiniML4- コンパイラの手始めに，MiniML4- プログラムを同等の意味を持つ$\mathcal{C}$プログラムに変換する方法を与える．プログラム変換の定義の一例として理解してほしい．MiniML4- のプログラムを受け取り$\mathcal{C}$のプログラムを返す変換を$\mathcal{I}$と呼ぶことにしよう．我々の目標は$\mathcal{C}$のプログラム$\mathcal{I}({d_1,\dots,d_n},e)$を定義することである．

まずはじめにMiniML4- の式から$\mathcal{C}$の式への変換を与えよう．MiniML4- と$\mathcal{C}$の違いは，後者ではすべての式の評価結果に名前がついていることである．したがって，評価の途中に出てくる式の値が必ず変数に束縛されるようなプログラムを生成すればよい．例えば[前の節](chap05-2.md)で出てきた MiniML4- の式`((x + 1) * 2) + (3 + 1)`を変換するには，

- 部分式`(x + 1) * 2` と `3 + 1` をそれぞれ$\mathcal{C}$の式に再帰的に変換し，変換結果を$e_1,e_2$として，
- 他の場所では使われていない変数$t_1$, $t_2$（このような変数を _fresh な変数 (fresh variables)_ ということがある）を作成し，
- $\mathbf{let}\ t_1 = e_1\ \mathbf{in}\ \mathbf{let}\ t_2 = e_2\ \mathbf{in}\ t_1 + t_2$を変換結果とすればよい．

このような変換を定義するには，式の形ごとに変換結果を与えればよい．（このような変換の仕方を _構文主導翻訳 (syntax-directed translation)_ という．）構文主導翻訳で変換$\mathcal{I}$を定義するならば，二項演算$e_1\ \mathit{op}\ e_2$のケースは

$$
\begin{array}{c}
\mathcal{I}(e_1\ \mathit{op}\ e_2) =
\begin{array}[t]{l}
\mathbf{let}\ t_1 = \mathcal{I}(e_1)\ \mathbf{in}\\
\mathbf{let}\ t_2 = \mathcal{I}(e_2)\ \mathbf{in}\\
\quad t_1\ \mathit{op}\ t_2
\end{array}
\end{array}
$$

と定義すれば良さそうである．

これで$\mathcal{C}$への変換はできるのであるが，今回は後々のことを見越して，もう少し欲張った変換を与えよう．MiniML4- では，以下のように，異なる束縛変数に同じ名前を与えることができる．
```
let x =
  let x = 2 in
  let x = 3 in
  x + x
in
x * x
```
このように異なる束縛変数に同じ名前がついていると，後々の変換で面倒なことになる．以前説明したように（TODO: リンク）束縛変数を一貫して名前変えしても，プログラムの意味は変わらない．そのため，異なる束縛変数が一意な名前を持つように変換したい．例えば，上記のプログラムは，
```
let t1 =
  let t2 = 2 in
  let t3 = 3 in
  t3 + t3
in
t1 * t1
```
のように変換しておけば，異なる束縛変数が異なる名前を持つことになる．

まとめると，変換$\mathcal{I}$は (1) MiniML4- を$\mathcal{C}$に変換しつつ，(2) 異なる束縛変数が異なる名前を持つようにする変換である．

## $\mathcal{I}$の定義

では，実際の変換の定義に入ろう．MiniML4- の式を$\mathcal{C}$の式に変換する部分の定義は以下のようになる．ただし，$\delta$は識別子から識別子への部分関数である．

$$
\begin{array}{rcl}
\mathcal{I}_\delta(x) &=& \delta(x)\\

\mathcal{I}_\delta(n) &=& n\\

\mathcal{I}_\delta(\mathbf{true}) &=& \mathbf{true}\\

\mathcal{I}_\delta(\mathbf{false}) &=& \mathbf{false}\\

\mathcal{I}_\delta(e_1 \mathit{op} e_2) &=&
\begin{array}[t]{l}
\mbox{$x_1$ and $x_2$ are fresh.}\\
\mathbf{let}\ x_1 = \mathcal{I}_\delta(e_1)\ \mathbf{in}\\
\mathbf{let}\ x_2 = \mathcal{I}_\delta(e_2)\ \mathbf{in}\\
\quad x_1\ \mathit{op}\ x_2
\end{array}\\

\mathcal{I}_\delta(\mathbf{if}\ e\ \mathbf{then}\ e_1\ \mathbf{else}\ e_2) &=&
\begin{array}[t]{l}
\mbox{$x$ is fresh.}\\
\mathbf{let}\ x = \mathcal{I}_\delta(e)\ \mathbf{in}\\
\quad\mathbf{if}\ x\ \mathbf{then}\ \mathcal{I}_\delta(e_1)\ \mathbf{else}\ \mathcal{I}_\delta(e_2)
\end{array}\\

\mathcal{I}_\delta(\mathbf{let}\ x = e_1\ \mathbf{in}\ e_2) &=&
\begin{array}[t]{l}
\mbox{$t_1$ is fresh.}\\
\mathbf{let}\ t_1 = \mathcal{I}_\delta(e_1)\ \mathbf{in}\ \mathcal{I}_{\delta[x \mapsto t_1]}(e_2)
\end{array}\\

%% \mathcal{I}_\delta(\ML{fun}\ x \rightarrow e) &=& \ML{fun}\ t_1 \rightarrow \mathcal{I}_{\delta[x \mapsto t_1]}(e)\\

\mathcal{I}_\delta(e_1 \; e_2) &=&
\begin{array}[t]{l}
  \mbox{$x_1$ and $x_2$ are fresh.}\\
  \mathbf{let}\ x_1 = \mathcal{I}_\delta(e_1)\ \mathbf{in}\\
	\mathbf{let}\ x_2 = \mathcal{I}_\delta(e_2)\ \mathbf{in}\\
  \quad x_1 \; x_2
\end{array}\\

\end{array}
$$

この変換$\mathcal{I}_\delta(e)$では，$e$のすべての部分式に$\mathbf{let}$式で名前をつけつつ，すでに$e$中で束縛されている変数の名前を一意になるように付け替えている．束縛変数の名前替えは一貫して行う必要がある．（つまり，束縛変数$x$を$t_1$に付け替えた場合，$x$のスコープ中での$x$の出現をすべて$t_1$に置き換える必要がある．そのため，どの変数をどの変数に名前替えしたかを覚えておく必要がある．これを記録しておくのが部分関数$\delta$である．それぞれのケースの右辺が言語$\mathcal{C}$の構文に添っていることを各自確認されたい．例えば，$\mathcal{I}$によって生成されたプログラムは，二項演算子${\mathit{op}}$の引数に必ず変数をとっている．

いくつかのケースについて説明をしておく．変換対象の式$e$の形に応じて場合分けする．

- $e = x$ のとき: $x$ はこの変換によって別の名前に名前替えされているはずなので，新しい名前を$\delta(x)$で取ってくる．
- $e = e_1\ \mathit{op}\ e_2$ のとき: 上で説明した通り．Fresh な名前$x_1, x_2$を生成している．
- $e = \mathbf{if}\ e'\ \mathbf{then}\ e_1\ \mathbf{else}\ e_2$ のとき: 変換後の式では，fresh な変数$x$を$e'$（の変換結果）の評価結果を束縛して，$\mathbf{if}$式を評価する．ここでは$e_1$と$e_2$の評価結果に変数を束縛しないことに注意しよう．そのようにして
$$
\begin{array}{l}
\mathbf{let}\ x = \mathcal{I}_\delta(e)\ \mathbf{in}\\
\mathbf{let}\ x_1 = \mathcal{I}_\delta(e_1)\ \mathbf{in}\\
\mathbf{let}\ x_2 = \mathcal{I}_\delta(e_2)\ \mathbf{in}\\
\quad\mathbf{if}\ x\ \mathbf{then}\ x_1\ \mathbf{else}\ x_2\\
\end{array}
$$
に変換してしまうと意味が変わってしまう．（$e$が$\mathbf{true}$に評価される式で，$e_2$が無限ループする式である場合に，変換前と変換後の式の評価結果をそれぞれ考えてみよう．）
- $e = \mathbf{let}\ x = e_1\ \mathbf{in}\ e_2$ のとき: $x$が束縛されているので，これを名前替えする必要がある．Fresh な変数$t_1$を生成して，$x$を$t_1$に名前替えする．$e_1$を変換するときには元の$\delta$を用いて，$e_2$を変換するときには，$x$が$t_1$に名前替えされたことを表すために，$\delta$に$\{x \mapsto t_1\}$を用いて変換する．

続いてプログラムと再帰関数定義の変換を定義する．まず，プログラムは$\mathbf{let rec}$式による相互再帰的な関数の定義$d_1,\dots,d_n$とメインの式$e$のペア$(\{d_1,\dots,d_n\},e)$であったことを思い出そう．（TODO: リンク）$d_1,\dots,d_n$で定義される関数の名前は，このプログラムに局所的な名前であるから，fresh な名前を割り当てることにする^[#トップレベルの関数名の名前替えについての注](#toplevelfun)．

$$
\begin{array}{rcl}

\mathcal{I}(\{d_1,\dots,d_n\},e) &=& (\{\mathcal{I}_\delta(d_1),\dots,\mathcal{I}_\delta(d_n)\},\mathcal{I}_\delta(e))\\
  &\mbox{where}&
    \begin{array}[t]{l}
      \{f_1,\dots,f_n\} = \mbox{$d_1,\dots,d_n$で定義されている関数名}\\
      \delta = \{f_1 \mapsto t_{f_1},\dots,f_n \mapsto t_{f_n}\}\\
    \end{array}\\

\mathcal{I}_\delta(\mathbf{let}\ \mathbf{rec}\ f = \mathbf{fun}\ x \rightarrow e) &=&
\mathbf{let}\ \mathbf{rec}\ \delta(f) = \mathbf{fun}\ t_1 \rightarrow \mathcal{I}_{\delta[x \mapsto t_1]}(e)\\
\end{array}
$$

- プログラム$(\{d_1,\dots,d_n\},e)$を変換する際には，まず$d_1,\dots,d_n$で定義されている関数の名前$f_1,\dots,f_n$を集め，それぞれに割り当てる fresh な名前$t_{f_1},\dots,t_{f_n}$を生成し，写像$\delta := \{f_1 \mapsto t_{f_1},\dots,f_n \mapsto t_{f_n}\}$を作る．$d_1,\dots,d_n$は相互再帰関数定義であり，それぞれの本体に$f_1,\dots,f_n$のうち任意の関数が現れうるから，$\delta$を用いて各関数の定義を変換し，メインの式$e$も変換する．
- 関数定義$\mathbf{let}\ \mathbf{rec}\ f = \mathbf{fun} x \rightarrow e$の変換においては，$f$がどの関数に名前変えされたかを$\delta$を用いて取ってくる．また，$x$に割り当てるべき fresh な名前$t_1$を生成し，$x$が$t_1$に名前変えされたことを$\delta$に記録してから，本体$e$を変換する．

<a href="#toplevelfun">トップレベルの関数名を名前替えするかどうか</a>: 今回の$\mathcal{I}$の定義ではトップレベルの関数の名前を名前替えすることにしているが，これをすべきかどうかはケースバイケースである．というのも，これらの関数名の中には，ライブラリ関数のような，プログラムの外部に公開される名前が含まれうるからである．これらの関数の名前を勝手に変えてしまうと，これらを呼び出す他のモジュールのコードとリンクする際に，関数が見つかりませんという旨のエラーが出るかもしれない．今回は外部のモジュールとのリンクを考えないので，トップレベルで定義される関数はすべてプログラムの内部のみで使われると考えることができるから，名前替えすることにする．