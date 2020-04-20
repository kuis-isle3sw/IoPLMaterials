{% include head.html %}

# MiniML2 のための型推論 (2): 型推論アルゴリズム

## 型推論アルゴリズムの入出力と，その設計の方針

[前節](chap04-2.md)の内容を踏まえて，型推論アルゴリズムを定義しよう．型推論アルゴリズムの仕様は，以下のように考えることができる．

- 入力: 型環境 $\Gamma$ と式 $e$．
- 出力: $\Gamma \vdash e : \tau$ という型判断が導出できるような型 $\tau$．もしそのような型がなければエラーを報告する．

さて，このような仕様を満たすアルゴリズムを，どのように設計したらよいだろうか．これは，$\Gamma \vdash e : \tau$ を根とする導出木を構築すればよい．では，このような導出木をどのように作ればよいだろうか．

この答えは型付け規則から得られる．上に挙げた型付け規則は _構文主導な規則 (syntax-directed rules)_ になっているというよい性質を持っている．これは，$\Gamma$と$e$が与えられたときに，$\Gamma \vdash e : \tau$が成り立つような$\tau$が存在するならば，これを導くような規則が$e$の形から一意に定まるという性質である．例えば，$\Gamma$と$e$が与えられ，$e$が$e_1 + e_2$という形をしていたとしよう．このとき，型推論アルゴリズムは$\Gamma \vdash e : \tau$を根とする導出木を構築しようとする．型付け規則をよく見ると，このような導出木は（存在するならば）最後の導出規則が$\textrm{T-Plus}$でしかありえない．すなわち，

$$
\begin{array}{c}
\vdots\\
\rule{6cm}{1pt}\\
\Gamma \vdash e_1 + e_2 : \tau_2
\end{array}
\textrm{T-Plus}
$$

という形の導出木だけを探索すればよいことになる．このように適用可能な最後の導出規則が$e$の形から一意に定まる型付け規則を構文主導であるという．

構文主導な型付け規則を持つ型システムでは，各規則を下から上に読むことによって型推論アルゴリズムを得ることができることが多い．
+ 例えば，$\textrm{T-Int}$ は入力式が整数リテラルならば，型環境に関わらず，$\mathbf{int}$ を出力する，と読むことができる．
+ $\textrm{T-Plus}$は，入力式$e$が$e_1+e_2$の形をしていたならば，$\Gamma$と$e_1$を再帰的に型推論アルゴリズムに入力して型を求めて（これを$\tau_1$とする）$\Gamma$と$e_2$とを再帰的に型推論アルゴリズムに入力して型を求めて（これを$\tau_2$とする）$\tau_1$も$\tau_2$も両方とも $\mathbf{int}$ であった場合には $\mathbf{int}$ 型を出力する，と読むことができる．<sup>[再帰呼び出しと導出木の構造についての注](#derivation)</sup>

<a name="derivation">再帰呼び出しと導出木の構造</a>: 明示的に導出木を構築していないので，なぜこれで「導出木を構築している」ことになるのかよくわからないかもしれない．この型推論アルゴリズムは再帰呼出しをしているが，この再帰呼出しの構造が導出木に対応している．

### Exercise ___ [必修]
MiniML2 のための型推論アルゴリズムを実装するためにコードに加えるべき変更を以下に示す．これを参考にしつつ，上記の$\textrm{T-Int}$と$\textrm{T-Plus}$のケースにならって，すべての場合について型推論アルゴリズムを完成させよ．また，インタプリタに変更を加え，型推論ができるようにせよ．

#### `syntax.ml` への変更

{% highlight ocaml %}
(* MiniML の型を表す OCaml の値の型 *)
type ty =
  TyInt
| TyBool

(* ty 型の値のための pretty printer *)
let pp_ty typ =
  match typ with
    TyInt -> print_srtring "int"
  | TyBool -> print_string "bool"
{% endhighlight %}

#### `cui.ml` への変更

{% highlight ocaml %}
open Typing

let rec read_eval_print env tyenv = (* New! 型環境を REPL で保持 *)
   print_string "# ";
   flush stdout;
   let decl = Parser.toplevel Lexer.main (Lexing.from_channel stdin) in
   let ty = ty_decl tyenv decl in (* New! let 宣言のための型推論 *)
   let (id, newenv, v) = eval_decl env decl in
     (* New! 型を出力するように変更 *)
     Printf.printf "val %s : " id;
     pp_ty ty;
     print_string " = ";
     pp_val v;
     print_newline();
     (* 型環境を次のループに渡す．let 宣言はまだないので，tyenv を新しくする必要はない． *)
     read_eval_print newenv tyenv 

(* New! initial_env のための型環境を作る *)
let initial_tyenv =
   Environment.extend "i" TyInt
     (Environment.extend "v" TyInt
       (Environment.extend "x" TyInt Environment.empty))

(* New! initial_tyenv を REPL の最初の呼び出しで渡す *)
let _ = read_eval_print initial_env initial_tyenv
{% endhighlight %}

### `typing.ml` への変更

{% highlight ocaml %}
open Syntax

exception Error of string

let err s = raise (Error s)

(* Type Environment *)
type tyenv = ty Environment.t

let ty_prim op ty1 ty2 = match op with
    Plus -> (match ty1, ty2 with 
                 TyInt, TyInt -> TyInt
               | _ -> err ("Argument must be of integer: +"))
    ...
  | Cons -> err "Not Implemented!"

let rec ty_exp tyenv = function
    Var x -> 
      (try Environment.lookup x tyenv with
          Environment.Not_bound -> err ("variable not bound: " ^ x))
  | ILit _ -> TyInt
  | BLit _ -> TyBool
  | BinOp (op, exp1, exp2) ->
      let tyarg1 = ty_exp tyenv exp1 in
      let tyarg2 = ty_exp tyenv exp2 in
        ty_prim op tyarg1 tyarg2
  | IfExp (exp1, exp2, exp3) ->
      ...
  | LetExp (id, exp1, exp2) ->
      ...
  | _ -> err ("Not Implemented!")

let ty_decl tyenv = function
    Exp e -> ty_exp tyenv e
  | _ -> err ("Not Implemented!")
{% endhighlight %}
