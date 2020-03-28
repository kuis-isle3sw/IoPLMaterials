{% include head.html %}

# 多相的 `let` の型推論

前節までの実装で実現される型(システム)は単相的であり，ひとつの変数をあたかも複数の型を持つように扱えない．例えば，

{% highlight ocaml %}
let f = fun x -> x  in
if f true then f 2 else 3;;
{% endhighlight %}

のようなプログラムは，`f` が，`if` の条件部では $\mathbf{bool} \rightarrow \mathbf{bool}$として，また，`then` 節では $\mathbf{int} \rightarrow \mathbf{int}$ として使われているため， 型推論に失敗してしまう．本節では，上記のプログラムなどを受理するよう _let 多相 (let polymorphism)_ を実装する．

本節を理解するためには OCaml の多相型の知識があったほうがよい．例えば，以下の二つのプログラムがどのように型付けされるか，あるいはされないかが理解できているだろうか．

+ `let id x = x in (id 3, id true)`
+ `(fun id -> (id 3, id true)) (fun x -> x)`

[OCaml入門テキスト](mltext.pdf) 4.2.1 節を復習してから，この先を読むことをおすすめする．

## 多相性と型スキーム

OCaml インタプリタに `let f = fun x -> x;;` を入力すると，その型は `'a -> 'a` であると表示される．ここで現れる型変数 `'a` は，[以前に導入した](chap04-5.md)ような後でその正体が判明する（今のところは）未知の型を表しているわけではなく，「どんな型にでも置き換えてよい」ことを示すための，いわば「穴ボコ」につけた名前である．そのために，`'a` を `int` で置き換えて `int->int` として扱うことで整数に適用できる関数の型としたり，`'a` を `bool` で置き換えて `bool->bool` として真偽値に適用する関数の型としたりすることができる．このように，OCaml の型変数には「今のところ未確定で後で正体が判明する型変数（ _単相的 (monomorphic)_）な型変数）」と「どんな型にでも置き換えてよい型変数（_多相的 (polymorphic)_な型変数）」の二種類がある．

この二種類を区別するために，多相的な型変数は $\forall \alpha.$ で束縛することにしよう．$\forall \alpha.$ が型の前に付けられた表現を _型スキーム (type scheme)_ と呼んで，型とは区別することにする．より正確には，型$\tau$の前に有限個の$\forall \alpha$が付けられた表現$\forall \alpha_1. \forall \alpha_2. \dots \forall \alpha_n. \tau$を型スキームと呼ぶ．（この型スキームを，型変数の列$(\alpha_1,\dots,\alpha_n)$をベクトル表記を借りて$\vec{\alpha}$と書くことにして，以下では$\forall \vec{\alpha}. \tau$と書くことにする．）例えば $\forall \alpha. \alpha \rightarrow \alpha$ は（型ではなく）型スキームである

型スキーム$\forall \vec{\alpha}. \tau$は，型変数の列$\vec{\alpha}$に相当する型を受け取って型を返す，いわば型から型への関数のようなものと見ることができる．例えば，型スキーム$\forall \alpha. \alpha \rightarrow \alpha$は，型$\mathbf{int}$を受け取ったら型$\mathbf{int} \rightarrow \mathbf{int}$を返し，型$\mathbf{bool}$を受け取ったら型$\mathbf{bool} \rightarrow \mathbf{bool}$を返すものと見ることができる．このように見ると，上記のプログラムでは，

- `let` で `f` が束縛された場所で `f` に型スキーム $\forall \alpha. \alpha \rightarrow \alpha$を割り当て，
- `if` の条件節の式 `f true` 中では割り当てられた型スキームに $\mathbf{bool}$ を与えることで `f` を$\mathbf{bool} \rightarrow \mathbf{bool}$型として使い，
- `then` 節の式 `f 2` 中では，割り当てられた型スキームに$\mathbf{int}$を与えることで `f` を $\mathbf{int} \rightarrow \mathbf{int}$型として使う，

ことで `f` の多相的な振る舞いを捉えることができる．


より形式的には，型$\tau$と型スキーム$\sigma$の定義を以下のように変更する．

$$
\begin{array}{rcl}
 \tau  & ::= & \alpha \mid \mathbf{int} \mid \mathbf{bool} \mid \tau_1 \rightarrow \tau_2 \\
 \sigma & ::= & \tau \mid \forall \alpha.\sigma
\end{array}
$$

新しく導入された型スキーム $\sigma$ が（上の説明の通り）型 $\tau$ の前に有限個の $\forall\alpha$ がついた形になっていることを確認されたい．また，型 $\tau$ は型スキームともみなせることに注意されたい．（$\forall \alpha.$がひとつもついていない型スキームである．）型スキーム中，$\forall$のついている型変数を _束縛されている (bound)_ といい，束縛されていない型変数（これらは単相的な型変数である）を _(自由である (free)_，という． 例えば $\forall \alpha. \alpha \rightarrow \alpha \rightarrow \beta$ において，$\alpha$ は束縛されており，$\beta$ は自由である．

その上で，型環境 $\Gamma$ を（変数の型への束縛の集合ではなく）変数の_型スキームへの_束縛の集合とする．これにより，`let` で束縛された変数には型スキーム$\forall\vec{\alpha}.\tau$を持たせておき，使用する際に$\vec{\alpha}$を適切な型で置き換えることで，多相的な振る舞いを型システムの上で表現することができる．

### 型と型スキームの区別

ここまでの説明から分かるように，これから導入する型システムでは型と型スキームを区別する．この区別は，技術的には，型に相当するメタ変数 $\tau$ と型スキームに相当するメタ変数$\sigma$を区別していることから生じており，この区別のために$(\forall \alpha.\alpha) \rightarrow (\forall \alpha.\alpha)$ のような表現は型とはみなされないようになっている．


なぜより素直（？）に，型の構文を

$$
\begin{array}{rcl}
 \tau  & ::= & \alpha \mid \mathbf{int} \mid \mathbf{bool} \mid \tau_1 \rightarrow \tau_2 \mid \forall \alpha. \tau
\end{array}
$$

として，型と型スキームを区別しない型システムを作らないのだろうか？一つの理由は，型推論問題の決定可能性の要請である．
このように型と型スキームを区別しない型システムを設計すると，より多くのプログラムを型付け可能とすることができ，型システムの表現力は上がるのだが，型推論問題が決定不能になることが知られている．型と型スキームを区別し（あとで見るように）多相性のある変数を導入できる場所を `let` や `let rec` に制限することで，実行時型エラーを含まない十分に多くのプログラムを型付け可能とすることができ，なおかつ型推論問題を決定可能とすることが可能となる．

## 型スキームを表す OCaml の型と，補助関数の定義

以下は `syntax.ml` に追加すべき，型スキームを表す型と，以下で使う補助関数の定義（の一部）である．

{% highlight ocaml %}
(* type scheme *)
type tysc = TyScheme of tyvar list * ty

let tysc_of_ty ty = TyScheme ([], ty)

let freevar_tysc tysc = ...
{% endhighlight %}

型スキームを表す型 `tysc` は唯一のコンストラクタ `TyScheme` を持つヴァリアント型である．$\forall \alpha_1 \dots \forall \alpha_n. \tau$ に対応する型スキームは $\mathtt{TyScheme}([\alpha_1; \dots; \alpha_n], \tau)$で表現される．関数 `freevar_tysc` は，[この Exercise](chap04-5.md#freevar_ty) で実装した関数 `freevar_ty` の拡張で，型スキーム$\sigma$を受け取り，$\sigma$に自由に出現する型変数の集合を計算する関数である．$\forall \vec{\alpha}$が型変数列$\vec{\alpha}$を束縛するため，型スキーム$\forall\vec{\alpha}.\tau$中に出現する自由な型変数の集合は，型$\tau$中に出現する型変数の集合から$\vec{\alpha}$中の型変数をすべて除いたものになる．`tysc_of_ty ty` は，型 `ty` を型スキーム `TyScheme([],ty)` に変換する関数である．

## 型付け規則の拡張

### 変数のための規則

次に，型付け規則をどのように拡張すればよいのか考えてみよう．型環境が変数から\underline{型スキーム}への部分関数であることを思い出されたい．変数のための規則は以下の通りになっている．

$$
\begin{array}{c}
\Gamma(x) = \forall \alpha_1,\dots,\alpha_n. \tau\\
\rule{10cm}{1pt}\\
\Gamma \vdash x : [\alpha_1\mapsto\tau_1,\ldots,\alpha_n\mapsto\tau_n]\tau
\end{array}
\textrm{T-PolyVar}
$$

すなわち，型環境中で$x$が束縛されている先の型スキームを$\forall \alpha_1,\dots,\alpha_n.\tau$とすると，$\tau$中の$\alpha_1,\dots,\alpha_n$を任意の型$\tau_1,\dots,\tau_n$で置き換えて得られる型を$x$の型としてよい．（まさにこれがやりたかったことである．）例えば，$\Gamma(`f`) = \forall \alpha.\tyFun{\alpha}{\alpha}$ とすると，

$$
  \Gamma \vdash f : \mathbf{int} \rightarrow \mathbf{int}
$$

や

$$
  \Gamma \vdash f : (\mathbf{int} \rightarrow \mathbf{int}) \rightarrow (\mathbf{int} \rightarrow \mathbf{int})
$$

といった型判断を導出することができる．

なお，あとで定義する型推論アルゴリズムは，プログラム全体に型が付くように適切な $\tau_1,\dots,\tau_n$を選ばなければならない．しかしながら，型付け規則を定義する段階においては，適切な$\tau_1,\dots,\tau_n$は何なのかを気にする必要はない．このように，型付け規則は数学的にきれいな形で書いておいて，型推論アルゴリズムで適切な$\tau_1,\dots,\tau_n$を選ぶ等の作業を頑張るといった戦略は，型システム関係の研究では頻出である．

### `let (rec)` 式に関する規則

さて，\ML{let}に関しては，大まかには以下のような規則になるはずである．

$$
\begin{array}{c}
  \Gamma \vdash e_1 : \tau_1 \quad
  \Gamma, x:\forall \alpha_1.\dots\forall \alpha_n. \tau_1 \vdash e_2 : \tau_2\\
\rule{10cm}{1pt}\\
  \Gamma \vdash \mathbf{let}\ x\ = e_1\ \mathbf{in}\ e_2 : \tau_2
\end{array}
\textrm{T-PolyLet?}
$$

TODO: ここまで書いた

これは，$e_1$の型から型スキームを作って，それを使って $e_2$ の型付
けをすればいいことを示している．さて，残る問題は
$\alpha_1,\ldots,\alpha_n$としてどんな型変数を選べばよいかである．も
ちろん，$\tau_1$に現れる型変数に関して $\forall$ をつけて，「未知
  の型」から「任意の型」に役割変更をするのだが，どんな型変数でも変更し
てよいわけではない．役割変更してよいものは\emph{$\Gamma$ に自由に出
  現しないもの}である．$\Gamma$ 中に(自由に)現れる型変数は，その後の
型推論の過程で正体がわかって特定の型に置き換えられる可能性があるので，
任意におきかえられるものとみなしてはまずいのである．例えば，
%
\begin{quote}\sf
let f x = ((let g y = (x, y) in g 4), x + 1) in ...
\end{quote}
%
という式を考え，その型推論の経過を書くと，
\begin{enumerate}
\item \textsf{x} の型を $\alpha$ とし，式 \ML{((let g y = (x, y) in g 4), x + 1)}の型推論をする．
\item 第1要素の式@let g y = (x, y) in g 4@の型推論を行う．このために，
  関数 \textsf{g} のパラメータ \textsf{y} の型を$\beta$ とし，型推論
  を行う．関数の型として $\beta \rightarrow \alpha * \beta$ が得られ
  る．
\end{enumerate}
ここで，@g@は@let@で束縛されているので，推論された型$\beta
\rightarrow \alpha * \beta$から型スキームを作り，$g$をこの型スキーム
に束縛する必要がある．ここで$\forall$で束縛してよい（つまり多相的に使っ
  て良い）型変数はどれであろうか．

もし $\forall \alpha.\forall \beta.\beta \rightarrow \alpha * \beta$
のように $\alpha$ についてまで束縛して（$\forall$ をつけて）しまっ
たとしよう．すると，関数@f@は型$\forall \alpha.\forall \beta.\beta
\rightarrow \alpha * \beta$を持つことになる．これは@f@に対してどのよ
うな型の引数でも渡せることを意味するから，@f true@といった式が@in@の後
に書かれていても許されることになる．しかし，@f@の定義中に@x + 1@という
式が現れているため，これでは@true + 1@を実行中に評価することになってし
まい，実行時に型エラーが起こってしまう．

何がおかしかったのだろうか．$\alpha$が@g@のスコープの外側で宣言されて
いる@x@の型であったことである．スコープの外側で宣言されている変数の型
は，その変数が外側でどのように使われているかに依存して決まるため，後に
なって特定の型にしなければならない場合がある．（実際にこの例では@x@が
  外側で@x+1@のように整数との加算に用いられているため，@x@の型を
  $\mathbf{int}$としなければならないことが，後になって分かる．）そのため，
$\forall$をつけて多相性を持たせてはならないのである．というわけで，正
しい型付け規則は，付帯条件をつけて，
%
\infrule[T-PolyLet]{
  \Gp e_1 : \tau_1 \andalso
  \Gamma, x:\forall \alpha_1.\cdots\forall \alpha_n. \tau_1 \p e_2 : \tau_2 \\
\mbox{($\alpha_1,\ldots,\alpha_n$ は $\tau_1$
  に自由に出現する型変数で $\Gamma$ には自由に出現しない)}
}{
  \Gp \ML{let}\ x\ \ML{=}\ e_1\ \ML{in}\ e_2 : \tau_2
}
%
となる．「$\Gamma$に自由に出現しない」という条件で，スコープ外で宣言さ
れた変数の型として使われている型変数が多相性を持たないように制限してい
る．

\subsection{型推論アルゴリズム概要}

ここまでのところが理解できれば，実は型推論の実装に対する変更はそんなに
多くはない．メジャーな変更が必要なのは変数式に関するケースと \ML{let}
式に関するケースである．図\ref{fig:MLlet2}にコードの変更点を示す．

まず，変数式に関するケースを考えよう．型変数に代入する型（型付け規則中
  の$\tau_1,\ldots,\tau_n$）はこの時点では未知であり，変数が他の部分
でどう使われるかに依存して決定される．そのため，ここでは
$\tau_1,\dots,\tau_n$に相当する新しい型変数を用意し，それらを使って
具体化を行う．

次に \ML{let} 式のケースである．ここでは，$e_1$ の型推論で得られた
$e_1$ の型 $\tau$ を型スキーム化する必要がある．型スキームする際に
は，\rn{T-PolyLet}の付帯条件を満たすように多相性を持たせる型変数を決定
する必要がある．この計算を行うための補助関数として図\ref{fig:MLlet2}中
で @closure@ を定義している．これは，型$\tau$ と型環境 $\Gamma$と
型代入 $S$ から，条件「$\alpha_1,\ldots,\alpha_n$は $\tau$ に自
  由に出現する型変数で $S\Gamma$ には自由に出現しない」を満たす型ス
キーム $\forall \alpha_1.\cdots.\forall \alpha_n. \tau$を求める関数
である．型代入 $S$を引数に取るのは，型推論の実装に便利なためである．

% \subsubsection{型スキームに対する型代入}

% 型推論の過程において(型環境中の)型スキームに対して型代入を作用させるこ
% とがある．この際，自由な型変数と束縛された型変数をともに@tyvar@型の値
% (実際は整数)で表現しているために，型スキームへの代入の定義は多少気をつ
% ける必要がある．というのは，置き換えた型中の自由な型変数と，束縛されて
% いる型変数が同じ名前で表現されている可能性があるためである． 

% 例えば，型スキーム $\forall \alpha. \tyFun{\alpha}{\beta}$ に
% $\subst(\beta) = \tyFun{\alpha}{\mathbf{int}}$
% であるような型代入を作用させることを考える．この代入は，$\beta$
% を未知の型を表す $\alpha$ を使った型で置き換える
% ことを示している．しかし，素朴に型スキーム中の $\beta$ を
% 置き換えると，$\forall \alpha.\tyFun{\alpha}{\tyFun{\alpha}{\mathbf{int}}}$
% という型スキームが得られてしまう．この型スキームでは，代入の前は，
% 未知の型を表す型変数であった，二番目の$\alpha$までが
% 任意に置き換えられる型変数になってしまっている．このように，代入によって
% 型変数の役割が変化してしまうのはまずいので避けなければいけない．

% このような変数の衝突問題を避けるための，ここで取る解決(回避)策は
% 束縛変数の名前替え，という手法である\footnote{他にもいろいろな回避策が
%   考えられる．「計算と論理」の講義で関連した問題に詳しく触れられる(か
%   もしれない)．}．

% これは，例えば $\forall \alpha.\tyFun{\alpha}{\alpha}$ と
% $\forall\beta.\tyFun{\beta}{\beta}$ が(文字列としての見かけは違っても)意味的には同じ型スキームを表している\footnote{
%   関数などの仮引数の名前を使われている場所といっしょに
%   変えても同じ関数を表していることと同様の現象と考えられる．}ことを
% 利用する．つまり，代入が起こる前に，新しい型変数を使って
% 一斉に束縛変数の名前を替えてしまって衝突が起こらないようにするのである．
% 上の例ならば，まず，$\forall \alpha.\tyFun{\alpha}{\beta}$ を
% $\forall \gamma.\tyFun{\gamma}{\beta}$ として，その後に $\beta$ を
% $\tyFun{\alpha}{\mathbf{int}}$ で置き換え，
% $\forall \gamma.\tyFun{\gamma}{\tyFun{\alpha}{\mathbf{int}}}$ を得ることになる．

% このような変数の名前替えを伴う代入操作の実装を図\ref{fig:MLlet2}に示す．
% @rename_tysc@，@subst_tysc@ がそれぞれ型スキームの名前替え，代入の
% ための関数である．

\begin{optexercise}{2}
  図\ref{fig:MLlet1}, \ref{fig:MLlet2} を参考にして，多相的\ML{let}
  式・宣言ともに扱える型推論アルゴリズムの実装を完成させよ．
\end{optexercise}

\begin{optexercise}{1}
  以下の型付け規則を参考にして，再帰関数が多相的に扱えるように，型推論機能を
拡張せよ．
%
\infrule[T-PolyLetRec]{
  \Gamma, f: \tau_1 \rightarrow \tau_2, x: \tau_1 \p e_1 : \tau_2 \andalso
  \Gamma, f:\forall\alpha_1,\ldots,\alpha_n.\tau_1 \rightarrow \tau_2 \p e_2 : \tau \\
  \mbox{($\alpha_1,\ldots,\alpha_n$ は $\tau_1$ もしくは $\tau_2$ に自由に出現する型変数で $\Gamma$ には自由に出現しない)}
}{
  \Gp \ML{let\ rec}\ f\ \ML{=}\ \ML{fun}\ x \rightarrow e_1\ \ML{in}\ e_2 : \tau
}
\end{optexercise}

\begin{optexercise}{3}
OCaml では，「@: @\metasym{型}」という形式で，式や宣言された変数の型を
指定することができる．この機能を扱えるように処理系を拡張せよ．
\end{optexercise}

\begin{optexercise}{3}
型推論時のエラー処理を，プログラマにエラー箇所がわかりやすくなるように
改善せよ．
\end{optexercise}


	
\begin{figure}
  \begin{flushleft}
@syntax.ml@\\
@main.ml@\\
\begin{boxedminipage}{\textwidth}
#{&}
...
let rec read_eval_print env tyenv =
  print_string "# ";
  flush stdout;
  let decl = Parser.toplevel Lexer.main (Lexing.from_channel stdin) in
  \graybox{let (newtyenv, ty) = ty_decl tyenv decl in}
  let (id, newenv, v) = eval_decl env decl in
    Printf.printf "val %s : " id;
    pp_ty ty;
    print_string " = ";
    pp_val v;
    print_newline();
    read_eval_print newenv \graybox{newtyenv}
#{@}
\end{boxedminipage}
 \end{flushleft}
  \caption{多相的\ML{let}のための型推論の実装(1)}
  \label{fig:MLlet1}
\end{figure}

\begin{figure}
  \begin{flushleft}
@typing.ml@\\
\begin{boxedminipage}{\textwidth}
#{&}
type tyenv = \graybox{tysc Environment.t}

\graybox{let rec freevar_tyenv tyenv =} ...

\graybox{let closure ty tyenv subst =}
  \graybox{let fv_tyenv' = freevar_tyenv tyenv in}
  \graybox{let fv_tyenv =}
    \graybox{MySet.bigunion}
      \graybox{(MySet.map}
          \graybox{(fun id -> freevar_ty (subst_type subst (TyVar id)))}
          \graybox{fv_tyenv') in}
  \graybox{let ids = MySet.diff (freevar_ty ty) fv_tyenv in}
    \graybox{TyScheme (MySet.to_list ids, ty)}

let rec subst_type subst = ...

let rec ty_exp tyenv = function
     Var x ->
      (try 
        \graybox{let TyScheme (vars, ty) = Environment.lookup x tyenv in}
        \graybox{let s = List.map (fun id -> (id, TyVar (fresh_tyvar ())))}
                  \graybox{vars in}
          \graybox{([], subst_type s ty)}
       with Environment.Not_bound -> err ("variable not bound: " ^ x))
   | ...
   \graybox{| LetExp (id, exp1, exp2) -> ...}

let ty_decl tyenv = function
    Exp e -> let (_, ty) = ty_exp tyenv e in \graybox{(tyenv, ty)}
  \graybox{| Decl (id, e) -> ...}
#{@}  
\end{boxedminipage}
 \end{flushleft}
  \caption{多相的\ML{let}のための型推論の実装(2)}
  \label{fig:MLlet2}
\end{figure}
