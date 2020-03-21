{% include head.html %}

# MiniML3 のための型推論

## 関数に関する型付け規則

次に，`fun`式と関数適用式
```
  e  ::=  ... \mid fun x -> e | e_1 e_2
```
で型推論アルゴリズムを拡張しよう．「$\tau_1$の値を受け取って（計算が停止すれば）$\tau_2$の値を返す関数」の型を$\tau_1 \rightarrow \tau_2$ とすると，型の定義は以下のように変更される．
$$
 \tau  ::= \mathbf{int} \mid \mathbf{bool} \mid \tau_1 \rightarrow \tau_2.
$$

これらの式に関する型付け規則を，背後の直観とともに説明する．

### `fun`式に関する規則

$$
\begin{array}{c}
\Gamma, x:\tau_1 \vdash e : \tau_2\\
\rule{10cm}{1pt}\\
\Gamma \vdash \mathbf{fun} x \rightarrow e : \tau_1 \rightarrow \tau_2
\end{array}
\textrm{T-Fun}
$$

引数 $x$ が $\tau_1$ を持つという仮定の下で関数本体 $e$ が $\tau_2$ 型を持つならば，$\mathbf{fun}\ x \rightarrow e$ が $\tau_1 \rightarrow \tau_2$ 型を持つことを導いて良い．$\mathbf{fun}\ x \rightarrow e$ が $x$ を受け取って $e$ を返す関数であることを考えれば納得できるであろう．

### 関数適用式に関する規則

$$
\begin{array}{c}
\Gamma \vdash e_1 : \tau_1 \rightarrow \tau_2 \quad
\Gamma \vdash e_2 : \tau_1\\
\rule{10cm}{1pt}\\
\Gamma \vdash e_1 \; e_2 : \tau_2
\end{array}
\textrm{T-App}
$$

$e_1$の型が関数型$\tau_1 \rightarrow \tau_2$であり，かつ，その引数の型$\tau_1$と$e_2$の型が一致している場合に，適用式全体に$e_1$の返り値型$\tau_2$がつくことを導いて良い．これも関数型の直観と関数適用のセマンティクスから納得できるだろう．

## 型推論アルゴリズムの設計に伴うちょっとした困難

次は型推論アルゴリズムの設計である．これらの規則を含めても型付け規則は構文主導なので，前節の「規則を下から上に読む」という戦略を使ってみよう．入力として型環境$\Gamma$と式$e$が与えられ，式$e$が$\mathbf{fun}\ x rightarrow e_1$という形をしていたとしよう．そうすると，\textrm{T-Fun}を下から上に使うことに読んで，以下のように型推論ができそうである．

- 型環境$\Gamma,x\COL\tau_1$と式$e_1$を入力として型推論アルゴリズムを再帰的に呼び出し型$\tau_2$を得る．
- 型$\tau_1 \rightarrow \tau_2$を$e$の型として返す．

ところが，これではうまくいかない．問題は，最初のステップで$e_1$の型を調べる際に作る型環境$\Gamma,x\COL\tau_1$である．ここで$x$の型として$\tau_1$を取っているが，この型をどのように取るべきかは，一般には$e_1$の中での$x$の使われ方と，この関数$\mathbf{fun}\ x \rightarrow e_1$がどのように使われうるかに依存するので，このタイミングで$\tau_1$を容易に決めることはできない．

簡単な例として，$\mathbf{fun}\ x \rightarrow x+1$という式を考えてみよう．これは，$\mathbf{int} \rightarrow \mathbf{int}$型の関数であることは「一目で」わかるので，一見，$x$の型を $\mathbf{int}$として推論を続ければよさそうだが，問題は，本体式である$x+1$を見ること無しには，$x$ の型が$\math{int}$であることは分からないということにある．

## 型変数，型代入と型推論アルゴリズムの仕様

今回のように，「今の所わからない情報があるために問題が解けない」という困難を，我々はどのように解決してきただろうか．よくやる戦略は， (1) 未知の情報をとりあえず変数において (2) その変数が満たすべき制約を生成し (3) その制約を満足する変数の値を求める，という方法である．（例えば，鶴亀算にしても，線形計画法のような数値最適化にしても，大体こういう感じのことをやっている．）

この戦略を使ってみよう．「$\tau_1$の適切な取り方が後にならないとわからない」という問題を解決するために「今のところ正体がわからない未知の型」を表す _型変数 (type variable)_ を導入する．型の文法を

$$
 \tau  ::=  \alpha \mid \mathbf{int} \mid \mathbf{bool} \mid \tau_1\rightarrow\tau_2
$$

のように拡張する．$\alpha$が新しく導入された型変数で，今の所どの型にすればよいかよくわからない型を表す．

そして，型推論アルゴリズムの出力として，型環境中に現れる型変数の「正体が何か」を返すことにする．上の例だと，とりあえず $x$ の型は $\alpha$ などと置いて，型推論を続ける．推論の結果，$x+1$ の型は $\mathbf{int}$ である，という情報に加え $\alpha = \mathbf{int}$という「型推論の結果$\alpha$は$\mathbf{int}$であることが判明しました」という情報が返ってくることになる．最終的に$\textrm{T-Fun}$より，全体の型は$\alpha \rightarrow \mathbf{int}$，つまり，$\mathbf{int} \rightarrow \mathbf{int}$ であることがわかる．

また，$\mathbf{fun}\ x \rightarrow \mathbf{fun}\ y \rightarrow x\; y$のような式を考えると，以下のような手順で型推論がすすむ．
- 新しい（つまり，他の型変数とカブらない）型変数$\alpha$を生成し，$x$の型を$\alpha$と置いて，本体，つまり $\mathbf{fun}\ y \rightarrow x\; y$の型推論を行う．
- 新しい型変数$\beta$を生成し，$y$の型を$\beta$と置いて，本体，つまり $x\; y$ の型推論を行う．
- $x\;y$ の型推論の結果，この式の型が別の新しい型変数 $\gamma$ を使って$\beta \rightarrow \gamma$と書け，$\alpha = \beta \rightarrow \gamma$であることが判明する．

さらに詳しい型推論アルゴリズムの中身については後述するが，ここで大事なことは，とりあえず未知の型として用意した型変数の正体が，推論の過程で徐々に明らかになっていくことである．

<a name="typevar">型変数と多相型</a>: OCaml の _多相型 (polymorphic type)_ とここで導入する型変数を含む型とを混同してはならない．OCaml においては，例えば `fun x -> x` が型 `'a -> 'a` を持ち，ここで表示される `'a` を「型変数」ということがある．しかし，この `'a` は上記の型変数とは異なる．この`'a` は「何の型にでも置き換えてよい」変数であるが，上記の型変数は「特定の型を表す」記号である．「任意の型で置き換え可能」な型変数は[多相型]()の節で扱う．

TODO: 多相型へのリンクをはる．

TODO: ここまで書いた．

## 実装の仕方

ここまで述べたことを実装したのが図\ref{fig:MLarrow1}である．型@ty@を型変数を表すコンストラクタ@TyVar@と関数型を表すコンストラクタ@TyFun@とで拡張する．@TyVar@は@tyvar@型の値を一つとるコンストラクタで@TyVar(tv)@という形をしており，これが型変数を表す．@tyvar@型は型変数の名前を表す型で，実体は整数型である．@TyFun@は@ty@型の引数を2つ持つ@TyFun(t1,t2)@という形をしており，これが型$\tyFun{\tau_1}{\tau_2}$を表す．

型推論アルゴリズムの実行中には，他のどの型変数ともかぶらない新しい型変
数を生成する必要がある．（このような型変数を\emph{fresh な型変数}と呼
  ぶ．）これを行うのが関数 @fresh_tyvar@ である．この関数は引数として
@()@を渡すと（すなわち@fresh_tyvar ()@のように呼び出すと）新しい未使用
の型変数を生成する．この関数は次に生成すべき型変数の名前を表す整数への
参照@counter@を保持しており，保持している値を新しい型変数として返し，
同時にその参照をインクリメントする．上で説明したように，\rn{T-Fun}のケー
スでは新しい型変数を生成するのだが，その際にこの関数を使用する．
\footnote{関数@fresh_tyvar@は呼び出すたびに異なる値を返すことに注意せ
  よ．これは@fresh_tryvar@が純粋な意味での計算ではない（参照の値の更新
    や参照からの値の呼び出しといった）\intro{副作用}{side effect}を持
  つためである．}

上述の型変数とその正体の対応関係を，\intro{型代入}{type substitution}
と呼ぶ．型代入（メタ変数として$\subst$を使用する．）は，型変数から型
への（定義域が有限集合な）写像である．以下では，$\subst\tau$ で
$\tau$ 中の型変数を $\subst$ を使って置き換えたような型，
$\subst\Gamma$ で，型環境中の全ての型に $\subst$ を適用したような
型環境を表す．例えば$\subst$が$\set{\alpha \mapsto \Int, \beta \mapsto
  \Bool}$であるとき，$\subst\alpha = \Int$であり，
$\subst(\tyFun{\alpha}{\beta}) = \tyFun{\Int}{\Bool}$であり，
$\subst(x\COL\alpha, y\COL\beta) = (x\COL\Int, y\COL\Bool)$である．
$\subst\tau$，$\subst\Gamma$ はより厳密には以下のように定義される．
%
\begin{eqnarray*}
\subst \alpha & = & \left\{
   \begin{array}{cp{10em}}
     \subst(\alpha) & if $\alpha \in \dom(\subst)$ \\
     \alpha & otherwise
   \end{array}\right. \\
\subst \Int & = & \Int \\
\subst \Bool & = & \Bool \\
\subst (\tyFun{\tau_1}{\tau_2}) & = & \tyFun{\subst\tau_1}{\subst\tau_2} \\
\\
\dom(\subst\Gamma)& = & \dom(\Gamma)  \\
(\subst\Gamma)(x) &= & \subst(\Gamma(x))
\end{eqnarray*}
%
$\subst\alpha$のケースが実質的な代入を行っているケースである．$\subst$
の定義域$\dom(\subst)$に$\alpha$が入っている場合は，$\subst$によって定
められた型（すなわち$\subst\alpha$）に写像する．$\Int$と$\Bool$は型変
数を含まないので，$\subst$を適用しても型に変化はない．$\tau$が
$\tyFun{\tau_1}{\tau_2}$であった場合は再帰的に$\subst$を適用する．

型代入を使うと，新しい型推論アルゴリズムの仕様は以下のように与えられる．
\begin{description}
\item[入力:] 型環境 $\Gamma$ と式 $e$
\item[出力:] $\subst\Gp e : \tau$ を結論とする判断が存在するような型
  $\tau$と代入 $\subst$
\end{description}
%% 上記の$\ML{fun}\ \ML{x} \rightarrow \ML{fun}\ \ML{y}\rightarrow
%% \ML{x\; y}$の型推論の実行は，概ね以下のようになるはずである．
%% \begin{enumerate}
%% \item 型変数$\alpha$を生成し，型環境$x\COL\alpha$と式
%%   $\ML{fun}\ \ML{y}\rightarrow \ML{x\; y}$とを入力して型推論アルゴリ
%%   ズムを再帰的に呼び出す．
%% \item 新しい型変数$\beta$を生成し，型環境$x\COL\alpha, y\COL\beta$と式
%%   $\ML{x\; y}$とを入力として型推論アルゴリズムを再帰的に呼び出す．
%% \item \ML{x\;y} の型推論の結果，この式の型が別の新しい型変数$\gamma$を
%%   使って$\tyFun{\beta}{\gamma}$と書け，$\alpha =
%%   \tyFun{\beta}{\gamma}$であることが判明する．
%% \end{enumerate}

型推論アルゴリズムを実装する前に，以降で使う補助関数を定義しておこう．

\begin{mandatoryexercise}
  \label{ex:freevarTy}
図\ref{fig:MLarrow1}中の @pp_ty@，@freevar_ty@ を完成させよ．
@freevar_ty@ は，与えられた型中の型変数の集合を返す関数で，型は
%
#{&}
val freevar_ty : ty -> tyvar MySet.t
#{@}
%
とする．型@'a MySet.t@ は@mySet.mli@ で定義されている@'a@を要素とする
集合を表す型である．
\end{mandatoryexercise}

さて，型推論アルゴリズムを実装するためには，型代入を表すデータ構造を決
める必要がある．様々な表現方法がありうるが，ここでは素直に型変数と型の
のペアのリストで表現することにしよう．すなわち，型代入を表す\OCAML{}の
型は以下のように宣言された@subst@である．
#{&}
type subst = (tyvar * ty) list
#{@}
@subst@型は@[(id1,ty1); ...; (idn,tyn)]@の形をしたリストである．このリ
ストは$[@idn@ \mapsto @tyn@] \circ \cdots \circ[@id1@ \mapsto @ty1@]
$という型代入を表すものと約束する．つまり，この型代入は「受け取った型
  中の型変数@id1@をすべて型@ty1@に置き換え，得られた型中の型変数@id2@
  をすべて型@ty2@に置き換え．．．得られた型中の型変数@idn@をすべて型
  @tyn@に置き換える」ような代入である．リスト中の型変数と型のペアの順
序と，代入としての作用の順序が逆になっていることに注意してほしい．また，
リスト中の型は後続のリストが表す型代入の影響を受けることに注意してほし
い．例えば，型代入@[(alpha, TyInt)]@が型@TyFun(TyVar alpha, TyBool)@に作
用すると，@TyFun(TyVar TyInt, TyBool)@となり，型代入
\begin{alltt}
  [(beta, (TyFun (TyVar alpha, TyInt))); (alpha, TyBool)]
\end{alltt}
が型@(TyVar beta)@に作用すると，まずリストの先頭の@(beta, (TyFun (TyVar alpha, TyInt)))@が作用して@TyFun (TyVar alpha, TyInt)@が得られ，
次にこの型にリストの二番目の要素の@(alpha, TyBool)@が作用して@TyFun(TyBool, TyInt)@が得られる．

以下の演習問題で，型代入を作用させる補助関数を実装しよう．
\begin{mandatoryexercise}
型代入に関する以下の型，関数を @typing.ml@ 中に実装せよ．
%
#{&}
type subst = (tyvar * ty) list

val subst_type : subst -> ty -> ty
#{@}
%

例えば，
%
#{&}
let alpha = fresh_tyvar () in
subst_type [(alpha, TyInt)] (TyFun (TyVar alpha, TyBool))
#{@}
% 
の値は @TyFun (TyInt, TyBool)@ になり，
%
#{&}
let alpha = fresh_tyvar () in
let beta = fresh_tyvar () in
subst_type [(beta, (TyFun (TyVar alpha, TyInt))); (alpha, TyBool)] (TyVar beta)
#{@}
の値は @TyFun (TyBool, TyInt)@ になる．
\end{mandatoryexercise}

\begin{figure}
  \begin{flushleft}
%% @Makefile@: \\
%%   \begin{boxedminipage}{\textwidth}
%% #{&}
%% OBJS=\graybox{mySet.cmo} syntax.cmo parser.cmo lexer.cmo \\
%%    environment.cmo typing.cmo eval.cmo main.cmo
%% #{@}
%%   \end{boxedminipage} \\
@syntax.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
...
\graybox{type tyvar = int}

 type ty =
     TyInt
   | TyBool
   \graybox{| TyVar of tyvar}
   \graybox{| TyFun of ty * ty}

(* pretty printing *)
let pp_ty = ...

\graybox{let fresh_tyvar =}
  \graybox{let counter = ref 0 in}
  \graybox{let body () =}
    \graybox{let v = !counter in}
      \graybox{counter := v + 1; v}
  \graybox{in body}

\graybox{let rec freevar_ty ty = ...} (*  ty -> tyvar MySet.t *)
#{@}
\end{boxedminipage}
\end{flushleft}
  \caption{\miniML{3} 型推論の実装(1)}
  \label{fig:MLarrow1}
\end{figure}

\subsection{単一化}

型変数と型代入を導入したところで型付け規則をもう一度見てみよう．
\rn{T-If}や\rn{T-Plus}などの規則は「条件式の型は \Bool でなくてはなら
  ない」「\ML{then}節と\ML{else}節の式の型は一致していなければならない」
   「引数の型は \Int でなくてはならない」という制約を課していることが
   わかる．

これらの制約を\miniML{2}に対する型推論では，型(すなわち @TyInt@ などの
定義される言語の型を表現した値) の比較を行うことでチェックしていた．例
えば与えられた式$e$が$e_1+e_2$の形をしていたときには，$e_1$の型
$\tau_1$と$e_2$の型$\tau_2$を再帰的にアルゴリズムを呼び出すことにより
推論し，\emph{それらが$\Int$であることをチェックしてから}全体の型とし
て$\Int$を返していた．

しかし，型の構文が型変数で拡張されたいま，この方法は不十分である．とい
うのは，部分式の型（上記の$\tau_1$と$\tau_2$）に型変数が含まれるかもし
れないからである．例えば，$\ML{fun\ x} \rightarrow \ML{1+x}$ という
式の型推論過程を考えてみる．まず，$\emptyset \vdash \ML{fun\ x}
\rightarrow \ML{1+x} \COL \tyFun{\Int}{\Int}$であることに注意しよう．
            （実際に導出木を書いてチェックしてみること．）したがって，
            型推論アルゴリズムは，この式の型として$\tyFun{\Int}{\Int}$
            を返すように実装するのが望ましい．

では，空の型環境$\emptyset$と上記の式を入力として，型推論アルゴリズム
がどのように動くべきかを考えてみよう．この場合，まず\rn{T-Fun}を下から
上に読んで，$\ML{x}$ の型を型変数$\alpha$ とおいた型環境
$x\COL\alpha$の下で$\ML{1+x}$の型推論をすることになる．その後，各部
分式$\ML{1}$と$\ML{x}$の型を，アルゴリズムを再帰的に呼び出すことで
推論し，$\Int$ と $\alpha$ を得る．\miniML{2}の型推論では，ここでそ
れぞれの型が$\Int$であるかどうかを単純比較によってチェックし，$\Int$で
なかったら型エラーを報告していた．しかし今回は後者の型が$\alpha$であっ
て$\Int$ではないため，\emph{単純比較による部分式の型のチェックだけでは
  型推論が上手くいかない}．

では，どうすれば良いのだろうか．定石として知られている手法は\intro{制約
  による型推論}{constraint-based type inference}という手法である．この
手法では，与えられたプログラムの各部分式から型変数に関する\intro{制
  約}{constraint}が生成されるものと見て，式をスキャンする過程で制約を集
め，その制約をあとで解き型代入を得る，という形で型推論アルゴリズムを設
計する．例えば，上記の例では，「$\alpha$は実は$\Int$である」という
制約が生成される．この制約を解くと型代入$\set{\alpha \mapsto \Int}$が得
られる．

上記の場合は制約が単純だったが，\rn{T-App}で関数$e_1$の受け取る引数の型
と$e_2$の型が一致すること，また\rn{T-If}で\ML{then}節と\ML{else}節の式
の型が一致することを検査するためには，より一般的な，
\begin{quotation}
  与えられた型のペアの集合 $\set{(\tau_{11}, \tau_{12}), \ldots,
    (\tau_{n1}, \tau_{n2})}$ に対して，$\subst \tau_{11} =
  \subst\tau_{12}$, \ldots, $\subst \tau_{n1} = \subst\tau_{n2}$ な
  る $\subst$ を求めよ
\end{quotation}
という制約解消問題を解かなければいけない．このような問題は\intro{単一
  化}{unification}問題と呼ばれ，型推論だけではなく，計算機による自動証
明などにおける基本的な問題として知られている．例え
ば，$\alpha$ と$\Int$ は $\subst(\alpha) = \Int$ なる型代
入$\subst$により単一化できる．ま
た，$\tyFun{\alpha}{\Bool}$ と
$\tyFun{(\tyFun{\Int}{\beta})}{\beta}$ は
$\subst(\alpha) = \tyFun{\Int}{\Bool}$ かつ $\subst(\beta) =
\Bool$ なる$\subst$ により単一化できる．

単一化問題は，対象（ここでは型）の構造や変数の動く範囲によっては，非常
に難しくなるが\footnote{問題設定によっては\intro{決定不能}{undecidable}に
  なることもある．決定不能であるとは，いい加減に言えば，かつすべての入
  力について有限時間で停止し正しい出力を返すプログラムが存在しないこと
  を言う．従って，決定不能な問題を計算機でなんとかしようとすると，一部
  の入力については正しくない答えを返すことを許容するか，一部の入力につ
  いては停止しないことを許容しなければならない．}，ここでは，型が単純
な木構造を持ち，型代入も単に型変数に型を割当てるだけのもの（\intro{一
    階の単一化}{first-order unification}と呼ばれる問題）なので，解であ
る型代入を求めるアルゴリズムが存在する．
\footnote{このアルゴリズムは，Prolog などの論理型言語と呼ばれるプログ
  ラミング言語の処理系において多く用いられる．}（しかも，求まる型代入
  がある意味で「最も良い」解であることがわかっている．）

一階の単一化を行うアルゴリズム$\UNIFY(X)$は，型のペアの集合$X$を入力と
し，$X$中のすべての型のペアを同じ型にするような型代入を返す．（そのよ
  うな型代入が存在しないときにはエラーを返す．）$\UNIFY$は以下のように
定義される．
%
\[
\begin{array}{lcl}
  \unify{\emptyset} & = & \emptyset\\
  \unifyX{\tau}{\tau} & = & \unify{X'} \\
  \unifyX{\tyFun{\tau_{11}}{\tau_{12}}}{\tyFun{\tau_{21}}{\tau_{22}}} &=&
   \unify{\set{(\tau_{11}, \tau_{21}), (\tau_{12}, \tau_{22})}\uplus X'}\\
  \unifyX{\alpha}{\tau} \quad (\mbox{if }\tau \neq \alpha) & = & \left\{
    \begin{array}{ll}
      \unify{[\alpha\mapsto\tau] X'} \circ
      [\alpha\mapsto\tau]
& (\alpha \not \in \FTV(\tau)) \\
      \error & (\mbox{その他})
    \end{array}\right. \\
  \unifyX{\tau}{\alpha} \quad (\mbox{if }\tau \neq \alpha) & = & \left\{
    \begin{array}{ll}
      \unify{[\alpha\mapsto\tau] X'} \circ
      [\alpha\mapsto\tau]
& (\alpha \not \in \FTV(\tau)) \\
      \error & (\mbox{その他})
    \end{array}\right. \\
  \unifyX{\tau_1}{\tau_2} &=& \error \quad (\mbox{その他の場合})
\end{array}
\]
%
ここで，$\emptyset$ は空の型代入を表し，$[\alpha\mapsto\tau]$は
$\alpha$を $\tau$ に写す（そしてそれ以外の型変数については何も行わ
  ない）型代入である．また$\FTV(\tau)$は $\tau$中に現れる型変数の
集合である．また，$X\uplus Y$ は，$X\cap Y = \emptyset$のときの
$X \cup Y$を表す記号である．

この$\UNIFY$の定義は以下のように$X$を入力とする単一化アルゴリズムとし
て読める:
\begin{itemize}
\item $X$が空集合であれば空の代入を返す．
\item そうでなければ，$X$から型のペア$(\tau_1,\tau_2)$を任意に一つ選び，
  それ以外の部分を$X'$とし，$(\tau_1,\tau_2)$がどのような形をしている
  かによって，以下の各動作を行う．
  \begin{itemize}
  \item $\tau_1$と$\tau_2$がすでに同じ形であった場合: $X'$について再帰
    的に単一化を行い，その結果を返せばよい．（$\tau_1$と$\tau_2$はすで
      に同じ形なので，残りの制約集合$X'$の解がそのまま全体の解となる．）
  \item 選んだ型のペアがどちらも関数型の形をしていた場合，すなわち
    $\tau_1$が$\tyFun{\tau_{11}}{\tau_{12}}$の形をしており，$\tau_2$が
    $\tyFun{\tau_{21}}{\tau_{22}}$の形をしていた場合: $\tau_1$と
    $\tau_2$が同じ形となるためには$\tau_{11}$と$\tau_{21}$が同じ形であ
    り，かつ$\tau_{12}$と$\tau_{22}$が同じ形であればよい．これを満たす
    型代入を求めるために，$\UNIFY$を
    $\set{(\tau_{11},\tau_{21}),(\tau_{12},\tau_{22})} \cup X'$を入力
    として再帰的に呼び出し，帰ってきた結果を全体の結果とする．
  \item 選んだ型のペアが型変数と型のペア，すなわち$(\alpha,\tau)$か
    $(\tau,\alpha)$の形をしていた場合\footnote{$(\alpha,\alpha)$の形だっ
    た場合はこのケースではなく，一つ前のケースに当てはまる．}: この場
    合，型変数$\alpha$は$\tau$でなければならないことがわかる．したがっ
    て，残りの制約$X'$中の$\alpha$に$\tau$を代入した制約
    $[\alpha\mapsto\tau] X'$を再帰的に解き，得られた解に$\alpha$を
    $\tau$に代入する写像$[\alpha \mapsto \tau]$を合成して得られる写像
    $\unify{[\alpha\mapsto\tau] X'} \circ [\alpha\mapsto\tau]$を解とし
    て返せばよい．ところが，ここで注意すべきことが一つある．もし$\tau$
    中に$\alpha$が現れていた場合\footnote{繰り返しになるが，$\tau$が
      $\alpha$自体であった場合はこのケースには当てはまらない．ここでエ
      ラーを報告しなければならないのは，例えば$\tau$が
      $\tyFun{\alpha}{\alpha}$の場合である．}，ここでエラーを検出しな
    ければならない．（なぜなのかを考察する課題を以下に用意している．）
  \end{itemize}
\end{itemize}

\begin{mandatoryexercise}
上の単一化アルゴリズムを
%
#{&}
val unify : (ty * ty) list -> subst
#{@}
%
として実装せよ．
\end{mandatoryexercise}

\begin{mandatoryexercise}
単一化アルゴリズムにおいて，$\alpha \not \in \FTV(\tau)$ という条件
はなぜ必要か考察せよ．
\end{mandatoryexercise}

\subsection{\miniML{3}型推論アルゴリズム}

以上を総合すると，\miniML{3}のための型推論アルゴリズムが得られる．例え
ば，$e_1\ML{+}e_2$ 式に対する型推論は，\rn{T-Plus}規則を下から上に読
むと，
\begin{enumerate}
\item $\Gamma, e_1$ を入力として型推論を行い，$\subst_1$，$\tau_1$ を得る．
\item $\Gamma, e_2$ を入力として型推論を行い，$\subst_2$，
  $\tau_2$ を得る．
\item 型代入 $\subst_1, \subst_2$ を $\alpha = \tau$ という形の方
  程式の集まりとみなして，$\subst_1 \cup \subst_2 \cup \set{(\tau_1,
    \Int), (\tau_2, \Int)}$ を単一化し，型代入$\subst_3$を得る．
\item $\subst_3$ と $\Int$ を出力として返す．
\end{enumerate}
となる．部分式の型推論で得られた型代入を方程式とみなして，再び単一化を
行うのは，ひとつの部分式から $[\alpha \mapsto \tau_1]$，もうひとつか
らは $[\alpha \mapsto \tau_2]$ という代入が得られた時に$\tau_1$ と
$\tau_2$ の整合性が取れているか（単一化できるか）を検査するためであ
る．

\begin{mandatoryexercise}
  他の型付け規則に関しても同様に型推論の手続きを与えよ(レポートの一部と
  してまとめよ)．そして，図\ref{fig:MLarrow2}を参考にして，型推論アルゴ
  リズムの実装を完成させよ．
\end{mandatoryexercise}

\begin{optexercise}{2}
再帰的定義のための \ML{let\ rec} 式の型付け規則は以下のように与えられる．
%
\infrule[T-LetRec]{
  \Gamma, f: \tau_1 \rightarrow \tau_2, x: \tau_1 \p e_1 : \tau_2 \andalso
  \Gamma, f:\tau_1 \rightarrow \tau_2 \p e_2 : \tau
}{
  \Gp \ML{let\ rec}\ f\ \ML{=}\ \ML{fun}\ x\ \rightarrow e_1\ \ML{in}\ e_2 : \tau
}
%
型推論アルゴリズムが \ML{let rec} 式を扱えるように拡張せよ．
\end{optexercise}

\begin{optexercise}{2}
以下は，リスト操作に関する式の型付け規則である．リストには要素の型を
$\tau$ として $\tyList{\tau}$ という型を与える．
%
\infrule[T-Nil]{
}{
 \Gp \ML{[]} : \tyList{\tau}
}
\infrule[T-Cons]{
  \Gp e_1 : \tau \andalso
  \Gp e_2 : \tyList{\tau}
}{
  \Gp e_1\ \ML{::}\ e_2 : \tyList{\tau}
}
\infrule[T-Match]{
  \Gp e_1 : \tyList{\tau} \andalso
  \Gp e_2 : \tau' \andalso
  \Gamma, x: \tau, y:\tyList{\tau} \p e_3 : \tau'
}{
  \Gp \ML{match}\ e_1\ \ML{with\ []} \rightarrow e_2\ \ML{|}\ 
   x\ \ML{::}\ y \rightarrow e_3 : \tau'
}
%
型推論アルゴリズムがこれらの式を扱えるように拡張せよ．
\end{optexercise}

\begin{figure}
  \begin{flushleft}
@typing.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
\graybox{type subst = (tyvar * ty) list}

\graybox{let rec subst_type subst t = ...}

\graybox{(* eqs_of_subst : subst -> (ty * ty) list }
\graybox{   型代入を型の等式集合に変換             *)}
\graybox{let eqs_of_subst s = ... }

\graybox{(* subst_eqs: subst -> (ty * ty) list -> (ty * ty) list }
\graybox{   型の等式集合に型代入を適用                           *)}
\graybox{let subst_eqs s eqs = ...}

\graybox{let rec unify l = ... }

let ty_prim op ty1 ty2 = match op with
    Plus -> \graybox{([(ty1, TyInt); (ty2, TyInt)], TyInt)}
  | ...

let rec ty_exp tyenv = function
    Var x ->
     (try \graybox{([],} Environment.lookup x tyenv\graybox{)} with
         Environment.Not_bound -> err ("variable not bound: " ^ x))
  | ILit _ -> \graybox{([], TyInt)}
  | BLit _ -> \graybox{([], TyBool)}
  | BinOp (op, exp1, exp2) ->
      let \graybox{(s1, ty1)} = ty_exp tyenv exp1 in
      let \graybox{(s2, ty2)} = ty_exp tyenv exp2 in
      \graybox{let (eqs3, ty) = ty_prim op ty1 ty2 in}
      \graybox{let eqs = (eqs_of_subst s1) @ (eqs_of_subst s2) @ eqs3 in}
      \graybox{let s3 = unify eqs in (s3, subst_type s3 ty)}
  | IfExp (exp1, exp2, exp3) -> ...
  | LetExp (id, exp1, exp2) -> ...
  \graybox{| FunExp (id, exp) ->}
      \graybox{let domty = TyVar (fresh_tyvar ()) in}
      \graybox{let s, ranty =}
       \graybox{ty_exp (Environment.extend id domty tyenv) exp in}
       \graybox{(s, TyFun (subst_type s domty, ranty))}
  \graybox{| AppExp (exp1, exp2) ->} ...
  | _ -> Error.typing ("Not Implemented!")
#{@}
\end{boxedminipage}
  \end{flushleft}
  \caption{\miniML{3} 型推論の実装(2)}
  \label{fig:MLarrow2}
\end{figure}
