{% include head.html %}

# MiniML3 のための型推論 (2): 実装

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

注意すべき点が2つある．

TODO: ここまで書いた

+ リスト中の型変数と型のペアの順序と，代入としての作用の順序は逆になっている．
+ リスト中の型は後続のリストが表す型代入の影響を受ける．例えば，型代入 `[(alpha, TyInt)]` が型 `TyFun(TyVar alpha, TyBool)` に作用すると，`TyFun(TyVar TyInt, TyBool)` となり，型代入 `[(beta, (TyFun (TyVar alpha, TyInt))); (alpha, TyBool)]`
\end{alltt}
が型@(TyVar beta)@に作用すると，まずリストの先頭の@(beta, (TyFun (TyVar alpha, TyInt)))@が作用して@TyFun (TyVar alpha, TyInt)@が得られ，
次にこの型にリストの二番目の要素の@(alpha, TyBool)@が作用して@TyFun(TyBool, TyInt)@が得られる

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

TODO: ここまで書いた

{% comment %}

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


\subsection{単一化}

型変数と型代入を導入したところで型付け規則をもう一度見てみよう．
\rn{T-If}や\rn{T-Plus}などの規則は「条件式の型は \mathbf{bool} でなくてはなら
  ない」「\ML{then}節と\ML{else}節の式の型は一致していなければならない」
   「引数の型は \mathbf{int} でなくてはならない」という制約を課していることが
   わかる．

これらの制約を\miniML{2}に対する型推論では，型(すなわち @TyInt@ などの
定義される言語の型を表現した値) の比較を行うことでチェックしていた．例
えば与えられた式$e$が$e_1+e_2$の形をしていたときには，$e_1$の型
$\tau_1$と$e_2$の型$\tau_2$を再帰的にアルゴリズムを呼び出すことにより
推論し，\emph{それらが$\mathbf{int}$であることをチェックしてから}全体の型とし
て$\mathbf{int}$を返していた．

しかし，型の構文が型変数で拡張されたいま，この方法は不十分である．とい
うのは，部分式の型（上記の$\tau_1$と$\tau_2$）に型変数が含まれるかもし
れないからである．例えば，$\ML{fun\ x} \rightarrow \ML{1+x}$ という
式の型推論過程を考えてみる．まず，$\emptyset \vdash \ML{fun\ x}
\rightarrow \ML{1+x} : \tyFun{\mathbf{int}}{\mathbf{int}}$であることに注意しよう．
            （実際に導出木を書いてチェックしてみること．）したがって，
            型推論アルゴリズムは，この式の型として$\tyFun{\mathbf{int}}{\mathbf{int}}$
            を返すように実装するのが望ましい．

では，空の型環境$\emptyset$と上記の式を入力として，型推論アルゴリズム
がどのように動くべきかを考えてみよう．この場合，まず\rn{T-Fun}を下から
上に読んで，$\ML{x}$ の型を型変数$\alpha$ とおいた型環境
$x:\alpha$の下で$\ML{1+x}$の型推論をすることになる．その後，各部
分式$\ML{1}$と$\ML{x}$の型を，アルゴリズムを再帰的に呼び出すことで
推論し，$\mathbf{int}$ と $\alpha$ を得る．\miniML{2}の型推論では，ここでそ
れぞれの型が$\mathbf{int}$であるかどうかを単純比較によってチェックし，$\mathbf{int}$で
なかったら型エラーを報告していた．しかし今回は後者の型が$\alpha$であっ
て$\mathbf{int}$ではないため，\emph{単純比較による部分式の型のチェックだけでは
  型推論が上手くいかない}．

では，どうすれば良いのだろうか．定石として知られている手法は\intro{制約
  による型推論}{constraint-based type inference}という手法である．この
手法では，与えられたプログラムの各部分式から型変数に関する\intro{制
  約}{constraint}が生成されるものと見て，式をスキャンする過程で制約を集
め，その制約をあとで解き型代入を得る，という形で型推論アルゴリズムを設
計する．例えば，上記の例では，「$\alpha$は実は$\mathbf{int}$である」という
制約が生成される．この制約を解くと型代入$\set{\alpha \mapsto \mathbf{int}}$が得
られる．

上記の場合は制約が単純だったが，\rn{T-App}で関数$e_1$の受け取る引数の型
と$e_2$の型が一致すること，また\rn{T-If}で\ML{then}節と\ML{else}節の式
の型が一致することを検査するためには，より一般的な，
\begin{quotation}
  与えられた型のペアの集合 $\set{(\tau_{11}, \tau_{12}), \ldots,
    (\tau_{n1}, \tau_{n2})}$ に対して，$\theta \tau_{11} =
  \theta\tau_{12}$, \ldots, $\theta \tau_{n1} = \theta\tau_{n2}$ な
  る $\theta$ を求めよ
\end{quotation}
という制約解消問題を解かなければいけない．このような問題は\intro{単一
  化}{unification}問題と呼ばれ，型推論だけではなく，計算機による自動証
明などにおける基本的な問題として知られている．例え
ば，$\alpha$ と$\mathbf{int}$ は $\theta(\alpha) = \mathbf{int}$ なる型代
入$\theta$により単一化できる．ま
た，$\tyFun{\alpha}{\mathbf{bool}}$ と
$\tyFun{(\tyFun{\mathbf{int}}{\beta})}{\beta}$ は
$\theta(\alpha) = \tyFun{\mathbf{int}}{\mathbf{bool}}$ かつ $\theta(\beta) =
\mathbf{bool}$ なる$\theta$ により単一化できる．

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
\item $\Gamma, e_1$ を入力として型推論を行い，$\theta_1$，$\tau_1$ を得る．
\item $\Gamma, e_2$ を入力として型推論を行い，$\theta_2$，
  $\tau_2$ を得る．
\item 型代入 $\theta_1, \theta_2$ を $\alpha = \tau$ という形の方
  程式の集まりとみなして，$\theta_1 \cup \theta_2 \cup \set{(\tau_1,
    \mathbf{int}), (\tau_2, \mathbf{int})}$ を単一化し，型代入$\theta_3$を得る．
\item $\theta_3$ と $\mathbf{int}$ を出力として返す．
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

{% endcomment %}
