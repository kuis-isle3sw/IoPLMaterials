{% include head.html %}

# MiniML3,4 のための型推論 (2): 型の等式制約と単一化

では，[前節](chap04-4.md)での説明を踏まえて，MiniML3 インタプリタに型推論機能を実装しよう．

## 型変数を表すデータ構造

まず，`syntax.ml` を改造して，型の構文に型変数を追加しよう．

{% highlight ocaml %}

type tyvar = int (* New! 型変数の識別子を整数で表現 *)

 type ty =
     TyInt
   | TyBool
   | TyVar of tyvar (* New! 型変数型を表すコンストラクタ *)
   | TyFun of ty * ty (* New! TFun(t1,t2) は関数型 t1 -> t2 を表す *)

(* New! 型のための pretty printer （実装せよ） *)
let pp_ty = ...

(* New! 呼び出すたびに，他とかぶらない新しい tyvar 型の値を返す関数 *)
let fresh_tyvar =
  let counter = ref 0 in (* 次に返すべき tyvar 型の値を参照で持っておいて， *)
  let body () =
    let v = !counter in
      counter := v + 1; v (* 呼び出されたら参照をインクリメントして，古い counter の参照先の値を返す *)
  in body

(*  New!  ty に現れる自由な型変数の識別子（つまり，tyvar 型の集合）を返す関数．実装せよ．*)
(* 型は ty -> tyvar MySet.t にすること．MySet モジュールの実装はリポジトリに入っているはず．*)
let rec freevar_ty ty = ... 

{% endhighlight %}

- 型変数の名前を表す型 `tyvar` を定義する．実体は整数型とする．
- 型 `ty` を型変数を表すコンストラクタ `TyVar` と関数型を表すコンストラクタ `TyFun` とで拡張する．`TyVar` は `tyvar` 型の値を一つとるコンストラクタで `TyVar(tv)` という形をしており，これが型変数を表す．`TyFun` は `ty` 型の引数を2つ持つ `TyFun(t1,t2)` という形をしており，これが型 $\tau_1 \rightarrow \tau_2$ を表す．

<a name="nameandtype">`ty` と `TyVar(tv)`</a>を混同しないように気をつけてほしい．（例年これを混同することによって課題が進まない人がたまにいる．）前者は型変数の名前を表す OCaml の型，後者は型変数型を表す OCaml の型である．

型推論アルゴリズムの実行中には，他のどの型変数ともかぶらない新しい型変数を生成する必要がある．（このような型変数を _fresh な型変数 (a fresh type variable)_ と呼ぶ．）これを行うのが関数 `fresh_tyvar` である．この関数は引数として `()` を渡すと（すなわち `fresh_tyvar ()` のように呼び出すと）新しい未使用の型変数を生成する．この関数は次に生成すべき型変数の名前を表す整数への参照 `counter` を保持しており，保持している値を新しい型変数として返し，同時にその参照をインクリメントする．上で説明したように，$\textrm{T-Fun}$ のケースでは新しい型変数を生成するのだが，その際にこの関数を使用する．<sup>[`fresh_tyvar`と副作用についての注](#freshtyvar)</sup>

<a name="freshtyvar">`fresh_tyvar` と副作用</a>: 関数 `fresh_tyvar` は呼び出すたびに異なる値を返すことに注意せよ．これは `fresh_tryvar` が数学的な意味での「関数」では計算ではないことを意味する．（数学の関数は，与えられた引数が同じなのに違う値になることはない．）このように，参照の値の更新や参照からの値の呼び出しといった，数学的な関数と異なる振る舞いをプログラムにさせるような計算上の作用のことを _副作用 (side effect)_ と呼ぶ．副作用には，このような破壊的代入の他に外部入出力（数学的な意味での関数は "Hello World!" とか呑気なことは出力しない），無限ループ（数学的な意味での関数は定義域全体で定義されている値から値への写像であり，無限ループという概念が存在しない），並行計算，非決定的計算，確率的計算等がある．

## 型代入とその実装


[前節](chap04-4.md)で説明した通り，MiniML3 の型推論アルゴリズムは型変数をどのような型にすれば入力されたプログラムが型付け可能になるかを出力する．この型変数とその正体の対応関係を，_型代入 (type substitution)_ と呼び，メタ変数として$\theta$を使用する．

型代入は型変数から型への（定義域が有限集合な）写像である．以下では，

+ $\theta\tau$ で型 $\tau$ 中の型変数を型代入 $\theta$ に従って置き換えて得られる型を，
+ $\theta\Gamma$ で，型環境 $\Gamma$ 中の全ての型に $\theta$ を適用して得られる型環境を

表すことにする．例えば$\theta$が $\{\alpha \mapsto \mathbf{int}, \beta \mapsto \mathbf{bool}\}$ という型代入であるとき，$\theta\alpha = \mathbf{int}$であり，
$\theta(\alpha \rightarrow \beta) = \mathbf{int} \rightarrow \mathbf{bool}$であり，
$\theta(x:\alpha, y:\beta) = (x:\mathbf{int}, y:\mathbf{bool})$である．
$\theta\tau$，$\theta\Gamma$ はより厳密には以下のように定義される．

$$
\begin{array}{rcl}
\theta \alpha & = & \left\{
   \begin{array}{cp{10em}}
     \theta(\alpha) & \mathit{if}\ \alpha \in \mathbf{dom}(\theta)\\
     \alpha & otherwise
   \end{array}\right. \\
\theta \mathbf{int} & = & \mathbf{int} \\
\theta \mathbf{bool} & = & \mathbf{bool} \\
\theta (\tau_1 \rightarrow \tau_2) & = & \theta\tau_1 \rightarrow \theta\tau_2 \\
\\
\mathbf{dom}(\theta\Gamma)& = & \mathbf{dom}(\Gamma)  \\
(\theta\Gamma)(x) &= & \theta(\Gamma(x))
\end{array}
$$

$\theta\alpha$のケースが実質的な代入を行っているケースである．$\theta$の定義域$\mathbf{dom}(\theta)$に$\alpha$が入っている場合は，$\theta$によって定められた型（すなわち$\theta\alpha$）に写像する．$\mathbf{int}$と$\mathbf{bool}$は型変数を含まないので，$\theta$を適用しても型に変化はない．$\tau$が$\tau_1 \rightarrow \tau_2$であった場合は再帰的に$\theta$を適用する．

型推論アルゴリズムを実装するためには，型代入を表すデータ構造を決める必要がある．様々な表現方法がありうるが，ここでは素直に型変数と型のペアのリストで表現することにしよう．すなわち，型代入を表す OCaml の型は以下のように宣言された `subst` である．

{% highlight ocaml %}
type subst = (tyvar * ty) list
{% endhighlight %}

`subst` 型は `[(id1,ty1); ...; (idn,tyn)]` の形をしたリストである．ここで，`id1,id2,...,idn` は型変数の名前（_つまり `tyvar` 型の値）であり，`ty1,ty2,...,tyn` は型（_つまり `ty` 型の値）である．このリストは$[\mathtt{idn} \mapsto \mathtt{tyn}] \circ \cdots \circ[\mathtt{id1} \mapsto \mathtt{ty1}]$という型代入を表すものと約束する．つまり，この型代入は

- 受け取った型中の型変数 `id1` をすべて型 `ty1` に置き換え，
- その後得られた型中の型変数 `id2` をすべて型 `ty2` に置き換え
- ．．．
- その後得られた型中の型変数 `idn` をすべて型 `tyn` に置き換える

という操作を行う型代入である．

注意すべき点がいくつかある．
 
+ 空リストは何も行わない代入（恒等変換）を表す．
+ 代入を型に適用すると，リスト中の型変数と型のペアで表される操作が先頭から順番に適用される．型代入 `[(id1,ty1); ...; (idn,tyn)]` を型に適用すると，最初に `id1` に `ty1` を代入する操作が行われる．
+ リスト中の型は後続のリストが表す型代入の影響を受ける．例えば，型代入 `[(alpha, TyInt)]` が型 `TyFun(TyVar alpha, TyBool)` に作用すると，`TyFun(TyInt, TyBool)` となり，型代入 `[(beta, (TyFun (TyVar alpha, TyInt))); (alpha, TyBool)]` が型 `(TyVar beta)` に作用すると，まずリストの先頭の `(beta, (TyFun (TyVar alpha, TyInt)))` が作用して `TyFun (TyVar alpha, TyInt)` が得られ，次にこの型にリストの二番目の要素の`(alpha, TyBool)` が作用して `TyFun(TyBool, TyInt)` が得られる．

## MiniML3 の型推論アルゴリズムの仕様

型代入を使うと，新しい型推論アルゴリズムの仕様は以下のように与えられる．

- 入力: 型環境 $\Gamma$ と式 $e$
- 出力: $\theta\Gamma \vdash e : \tau$ を結論とする判断が存在するような型$\tau$と代入 $\theta$

<!-- %% 上記の$\ML{fun}\ \ML{x} \rightarrow \ML{fun}\ \ML{y}\rightarrow -->
<!-- %% \ML{x\; y}$の型推論の実行は，概ね以下のようになるはずである． -->
<!-- %% \begin{enumerate} -->
<!-- %% \item 型変数$\alpha$を生成し，型環境$x:\alpha$と式 -->
<!-- %%   $\ML{fun}\ \ML{y}\rightarrow \ML{x\; y}$とを入力して型推論アルゴリ -->
<!-- %%   ズムを再帰的に呼び出す． -->
<!-- %% \item 新しい型変数$\beta$を生成し，型環境$x:\alpha, y:\beta$と式 -->
<!-- %%   $\ML{x\; y}$とを入力として型推論アルゴリズムを再帰的に呼び出す． -->
<!-- %% \item \ML{x\;y} の型推論の結果，この式の型が別の新しい型変数$\gamma$を -->
<!-- %%   使って$\tyFun{\beta}{\gamma}$と書け，$\alpha = -->
<!-- %%   \tyFun{\beta}{\gamma}$であることが判明する． -->
<!-- %% \end{enumerate} -->

それでは，型代入を型に適用する関数を（この後使う補助関数とともに）定義しよう．

### <a name="freevar_ty">Exercise ___ [必修]</a>

`pp_ty` と `freevar_ty` を完成させよ．`freevar_ty` は，与えられた型中の型変数の集合を返す関数で，型は `ty -> tyvar MySet.t` とする．型 `'a MySet.t` は `mySet.mli` で定義されている型 `'a` の値を要素とする集合を表す値の型である．


### Exercise ___ [必修]

型代入に関する以下の型，関数を `typing.ml` 中に実装せよ．

{% highlight ocaml %}
type subst = (tyvar * ty) list

	val subst_type : subst -> ty -> ty
{% endhighlight %}

例えば，

{% highlight ocaml %}
let alpha = fresh_tyvar () in
subst_type [(alpha, TyInt)] (TyFun (TyVar alpha, TyBool))
{% endhighlight %}

の値は `TyFun (TyInt, TyBool)` になり，

{% highlight ocaml %}
let alpha = fresh_tyvar () in
let beta = fresh_tyvar () in
subst_type [(beta, (TyFun (TyVar alpha, TyInt))); (alpha, TyBool)] (TyVar beta)
{% endhighlight %}

の値は `TyFun (TyBool, TyInt)` になる．

## 制約に基づく型推論

型変数と型代入を導入したところで型付け規則をもう一度見てみよう．$\textrm{T-If}$ や $\textrm{T-Plus}$ などの規則は「条件式の型は $\mathbf{bool}$ でなくてはならない」「`then` 節と `else` 節の式の型は一致していなければならない」「引数の型は $\mathbf{int}$ でなくてはならない」という制約を課していることがわかる．

これらの制約を，MiniML2 に対する型推論では，推論された MiniML2 の型（すなわち `TyInt` などの定義される言語の型を表現した OCaml の値) の形を調べることでチェックしていた．例えば与えられた式 `e` が `$e_1+e_2` の形をしていたときには，`e_1` の型 $\tau_1$ と `e_2` の型 $\tau_2$ を再帰的にアルゴリズムを呼び出すことにより推論し，_それらが$\mathbf{int}$であることをチェックしてから_，全体の型として$\mathbf{int}$を返していた．

しかし，型の構文が型変数で拡張されたいま，この方法は不十分である．というのは，部分式の型（上記の $\tau_1$ と $\tau_2$）に型変数が含まれるかもしれないからである．例えば，`fun x -> 1+x` という式の型推論過程を考えてみる．まず，$\emptyset \vdash \mathbf{fun}\ x \rightarrow 1+x : \mathbf{int} \rightarrow \mathbf{int}$であることに注意しよう．（実際に導出木を書いてチェックしてみること．）したがって，型推論アルゴリズムは，この式の型として $\mathbf{int} \rightarrow \mathbf{int}$ を返すように実装するのが望ましい．

では，空の型環境 $\emptyset$ と上記の式を入力として，型推論アルゴリズムがどのように動くべきかを考えてみよう．この場合，まず $\textrm{T-Fun}$ を下から上に読んで，$x$ の型を型変数$\alpha$ とおいた型環境 $x:\alpha$の下で `1+x` の型推論をすることになる．その後，各部分式 `1` と `x` の型を，アルゴリズムを再帰的に呼び出すことで推論し，$\mathbf{int}$ と $\alpha$ を得る．MiniML2 の型推論では，ここでそれぞれの型が$\mathbf{int}$であるかどうかを単純比較によってチェックし，$\mathbf{int}$でなかったら型エラーを報告していた．しかし今回は後者の型が $\alpha$ であって $\mathbf{int}$ ではないため，_単純比較による部分式の型のチェックだけでは型推論が上手くいかない_．

では，どうすれば良いのだろうか．よく使われる手法として _制約による型推論 (constraint-based type inference)_ という手法がある．この手法では，

- 式をスキャンしながら，与えられたプログラムが型付け可能であるための _制約 (constraint)_ を生成し，（_制約生成 (constraint generation)_）
- その制約をあとで解き型代入を得る，（_制約解消 (constraint solving)_）

という形で型推論アルゴリズムを設計する．例えば，上記の例では，「$\alpha$ と $\mathbf{int}$ が等しい」という制約が生成される．この制約を解くと型代入 $\{\alpha \mapsto \mathbf{int}\}$ が得られる．

上記の場合は制約が単純だったが，$\textrm{T-App}$で

- 関数 $e_1$ の型が関数型であり，
- その引数の型と $e_2$ の型が一致すること，

や，$\textrm{T-If}$ で

- `then` 節と `else` 節の式の型が一致すること

などを表現する際にはもう少し複雑な制約が生成されることがある．

一般的には，MiniML3 の型推論の範囲内では，型の間の等式制約 $\{\tau_{11} = \tau_{12}, \dots, \tau_{n1} = \tau_{n2}\}$ によって，式が型付け可能であるための条件を表現することが可能となる．となれば，型推論は，与えられた型の等式制約 $\{\tau_{11} = \tau_{12}, \dots, \tau_{n1} = \tau_{n2}\}$ の解となる型代入 $\theta$，すなわち $\theta \tau_{11} = \theta\tau_{12}, \ldots, \theta \tau_{n1} = \theta\tau_{n2}$ をすべて満たすような $\theta$ を求める問題に帰着される．

## 単一化による型の等式制約の解法

このように項の間の等式制約を満たす代入を求める問題は _単一化 (unification)_ 問題と呼ばれ，型推論だけではなく，Prolog 等の論理プログラミング言語や Coq 等の証明支援系等にも現れる基本的な問題として知られている．例えば，$\alpha$ と$\mathbf{int}$ は $\theta(\alpha) = \mathbf{int}$ なる型代入$\theta$により単一化できる．また，$\alpha \rightarrow \mathbf{bool}$ と $(\mathbf{int} \rightarrow \beta) \rightarrow \beta$ は$\theta(\alpha) = \mathbf{int} \rightarrow \mathbf{bool}$ かつ $\theta(\beta) =\mathbf{bool}$ なる$\theta$ により単一化できる．

単一化問題は，項（ここでは型）の構造や変数の動く範囲など，問題設定によっては _決定不能 (undecidable)_ になることもある．<sup>[決定不能性についての注](#undecidable)</sup>しかし，ここでは型が単純な木構造を持ち，型代入も単に型変数に型を割当てるだけのもの（_一階の単一化 (first-order unification)_ と呼ばれる問題）なので，解である型代入を求めるアルゴリズムが存在する．（このアルゴリズムは，Prolog などの論理型言語と呼ばれるプログラミング言語の処理系において多く用いられる．また，求まる型代入がある意味で「最も一般的な」解であることがわかっている．）

TODO: mgu について追記？

<a name="undecidable">決定不能性について</a>: ある問題が決定不能であるとは，いい加減に言えば，すべての入力に対して正しい答えを返し，かつすべての入力について有限時間で停止するプログラムが存在しないことを言う．従って，決定不能な問題を計算機でなんとかしようとすると，一部の入力については正しくない答えを返すことを許容するか，一部の入力については停止しないことを許容しなければならない．

一階の単一化を行うアルゴリズム$\mathit{Unify}(X)$は，型の等式制約 $X$ を入力とし，$X$ 中のすべての型のペアを同じ型にするような型代入を返す．（そのような型代入が存在しないときにはエラーを返す．）$\mathit{Unify}$ の定義を以下に示す．

$$
\begin{array}{lcl}
  \mathit{Unify}(\emptyset) & = & \emptyset\\
  \mathit{Unify}(X' \uplus \{\tau = \tau\}) & = & \mathit{Unify}(X') \\
  \mathit{Unify}(X' \uplus \{\tau_{11} \rightarrow \tau_{12} = \tau_{21} \rightarrow \tau_{22}\} &=&
   \mathit{Unify}(\{\tau_{11} = \tau_{21}, \tau_{12} = \tau_{22}\} \uplus X')\\
  \mathit{Unify}(X' \uplus \{\alpha = \tau\}) \quad (\mbox{if }\tau \neq \alpha) & = & \left\{
    \begin{array}{ll}
	  \mathit{Unify}([\alpha\mapsto\tau] X') \circ [\alpha\mapsto\tau] & (\alpha \not \in \mathbf{FTV}(\tau)) \\
	  \mathbf{Error} & (\mbox{Otherwise})
    \end{array}\right. \\
  \mathit{Unify}(X' \uplus \{\tau = \alpha\}) \quad (\mbox{if }\tau \neq \alpha) & = & \left\{
    \begin{array}{ll}
      \mathit{Unify}([\alpha\mapsto\tau] X') \circ [\alpha\mapsto\tau] & (\alpha \not \in \mathbf{FTV}(\tau)) \\
      \mathbf{Error} & (\mbox{Otherwise})
    \end{array}\right. \\
  \mathit{Unify}(X \uplus \tau_1 = \tau_2) &=& \mathbf{Error} \quad (\mbox{Otherwise})
\end{array}
$$

ここで，$\emptyset$ は空の型代入を表し，$[\alpha\mapsto\tau]$ は $\alpha$を $\tau$ に写す（そしてそれ以外の型変数については何も行わない）型代入である．また$\mathbf{FTV}(\tau)$ は（[前に実装した](#freevar_ty) `freevar_ty` で計算される） $\tau$中に現れる型変数の集合である．また，$X \uplus Y$ は，$X \cap Y = \emptyset$ のときの $X \cup Y$を表す記号である．

この$\mathit{Unify}$の定義は以下のように$X$を入力とする単一化アルゴリズムとして読める:

+ $X$が空集合であれば空の代入を返す．
+ そうでなければ，$X$から等式制約 $\tau_1 = \tau_2$を任意に一つ選び，それ以外の部分を $X'$ とし，制約 $\tau_1 = \tau_2$がどのような形をしているかによって，以下の各動作を行う．
  + $\tau_1$と$\tau_2$がすでに同じ形であった場合: $X'$について再帰的に単一化を行い，その結果を返せばよい．（$\tau_1$と$\tau_2$はすでに同じ形なので，残りの制約集合$X'$に対する解がそのまま全体の解となる．）
  + $\tau_1$ も $\tau_2$ も関数型の形をしていた場合，すなわち$\tau_1$が$\tau_{11} \rightarrow \tau_{12}$の形をしており，$\tau_2$が $\tau_{21} \rightarrow \tau_{22}$の形をしていた場合: $\tau_1$と $\tau_2$が同じ形となるためには$\tau_{11}$と$\tau_{21}$が同じ形であり，かつ$\tau_{12}$と$\tau_{22}$が同じ形であればよい．これを満たす型代入を求めるために，$\mathit{Unify}$ を $\{\tau_{11} = \tau_{21}, \tau_{12} = \tau_{22}\} \cup X'$ を入力として再帰的に呼び出し，帰ってきた結果を全体の結果とする．
  + $\tau_1$ と $\tau_2$ の片方が型変数だった場合，すなわち選んだ制約が $\alpha = \tau$ か $\tau = \alpha$ の形をしていた場合<sup>[$\alpha = \alpha$の場合についての注](#alphaeqalpha)</sup>: この場合，型変数$\alpha$は$\tau$でなければならないことがわかる．したがって，残りの制約$X'$中の$\alpha$に$\tau$を代入した制約$[\alpha\mapsto\tau] X'$を作り，これを再帰的に解き，得られた解に$\alpha$を$\tau$に代入する写像$[\alpha \mapsto \tau]$を合成して得られる写像$\mathit{Unify}([\alpha\mapsto\tau] X') \circ [\alpha\mapsto\tau]$を解として返せばよい．ところが，ここで注意すべきことが一つある．もし$\tau$中に$\alpha$が現れていた場合<sup>[$\alpha = \alpha$の場合の注2](#alphaeqalpha2)</sup>，ここでエラーを検出しなければならない．（なぜなのかを考察する課題を以下に用意している．）この条件のチェックのことを _オカーチェック (occur check)_ と呼ぶ．
+ これら以外の場合: エラーを報告する．

<a name="alphaeqalpha">$\alpha = \alpha$ の形だった場合はこのケースではなく，一つ前のケースに当てはまる．</a>

<a name="alphaeqalpha2">繰り返しになるが，$\tau$が$\alpha$自体であった場合はこのケースには当てはまらない．ここでエラーを報告しなければならないのは，例えば$\tau$が$\alpha \rightarrow \alpha$の場合である．</a>

### Exercise ___ [必修]

上の単一化アルゴリズムを `(ty * ty) list -> subst` 型の関数 `unify` として実装せよ．

### Exercise ___ [必修]

単一化アルゴリズムにおいて，オカーチェックの条件 $\alpha \not \in \mathbf{FTV}(\tau)$ はなぜ必要か考察せよ．