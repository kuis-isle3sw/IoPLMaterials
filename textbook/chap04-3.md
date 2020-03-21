{% include head.html %}

# MiniML2 のための型推論 (2): 型推論アルゴリズム

[前節](chap04-2.md)の内容を踏まえて，型推論アルゴリズムを定義しよう．型推論アルゴリズムの仕様は，以下のように考えることができる．

{% comment %}

\begin{description}
  \item[入力:] 型環境 $\Gamma$ と式 $e$．
  \item[出力:] $\Gp e : \tau$ という型判断が導出できるような型
    $\tau$．もしそのような型がなければエラーを報告する．
\end{description}

さて，このような仕様を満たすアルゴリズムを，どのように設計したらよいだ
ろうか．これは，$\Gp e : \tau$を根とする導出木を構築すればよい．では，
このような導出木をどのように作ればよいだろうか．

この答えは型付け規則から得られる．上に挙げた型付け規則は\mathbf{int}ro{構文主
  導な規則}{syntax-directed rules}になっているというよい性質を持ってい
る．これは，$\Gamma$と$e$が与えられたときに，$\Gamma \p e : \tau$が
成り立つような$\tau$が存在するならば，これを導くような規則が$e$の形か
ら一意に定まるという性質である．例えば，$\Gamma$と$e$が与えられ，$e$が
$e_1 + e_2$という形をしていたとしよう．このとき，型推論アルゴリズムは
$\Gamma \p e : \tau$を根とする導出木を構築しようとする．型付け規則
をよく見ると，このような導出木は（存在するならば）最後の導出規則が
\rn{T-Plus}でしかありえない．すなわち，
\[
\infer[\rn{T-Plus}]
      {\Gamma \p e : \tau}
      {\vdots}
\]
という形の導出木だけを探索すればよいことになる．このように適用可能な最
後の導出規則が$e$の形から一意に定まる型付け規則を構文主導であるという．

構文主導な型付け規則を持つ型システムでは，各規則を下から上に読むことに
よって型推論アルゴリズムを得ることができることが多い．例えば，
\rn{T-Int} は入力式が整数リテラルならば，型環境に関わらず，\mathbf{int} を出力
する，と読むことができる．また，\rn{T-Plus}は
\begin{quote}
  入力式$e$が$e_1+e_2$の形をしていたならば，$\Gamma$と$e_1$を再帰的に
  型推論アルゴリズムに入力して型を求めて（これを$\tau_1$とする）
  $\Gamma$と$e_2$とを再帰的に型推論アルゴリズムに入力して型を求めて
  （これを$\tau_2$とする）$\tau_1$も$\tau_2$も両方とも \mathbf{int} であった場
  合には \mathbf{int} 型を出力する
\end{quote}
と読むことができる．\footnote{明示的に導出木を構築していないので，なぜ
  これで「導出木を構築している」ことになるのかよくわからないかもしれな
  い．この型推論アルゴリズムは再帰呼出しをしているが，この再帰呼出しの
  構造が導出木に対応している．}
\begin{mandatoryexercise}
図\ref{fig:MLb1}, 図\ref{fig:MLb2}に示すコードを参考にして，型推論アル
ゴリズムを完成させよ．
% （ソースファイルとして @typing.ml@ を追加するので，@make depend@ の実行を一度行うこと．）
\end{mandatoryexercise}

\begin{figure}
  \begin{flushleft}
%% @Makefile@: \\
%%   \begin{boxedminipage}{\textwidth}
%% #{&}
%% OBJS=syntax.cmo parser.cmo lexer.cmo \\
%%    environment.cmo \graybox{typing.cmo} eval.cmo main.cmo
%% #{@}
%%   \end{boxedminipage} \\
@syntax.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
\graybox{type ty =}
    \graybox{TyInt}
  \graybox{| TyBool}

\graybox{let pp_ty = function}
      \graybox{TyInt -> print_string "int"}
    \graybox{| TyBool -> print_string "bool"}
#{@}
  \end{boxedminipage} \\
@main.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
\graybox{open Typing}

let rec read_eval_print env \graybox{tyenv} =
   print_string "# ";
   flush stdout;
   let decl = Parser.toplevel Lexer.main (Lexing.from_channel stdin) in
   \graybox{let ty = ty_decl tyenv decl in}
   let (id, newenv, v) = eval_decl env decl in
     \graybox{Printf.printf "val %s : " id;}
     \graybox{pp_ty ty;}
     \graybox{print_string " = ";}
     pp_val v;
     print_newline();
     read_eval_print newenv \graybox{tyenv}

\graybox{let initial_tyenv =}
   \graybox{Environment.extend "i" TyInt}
     \graybox{(Environment.extend "v" TyInt}
       \graybox{(Environment.extend "x" TyInt Environment.empty))}

let _ = read_eval_print initial_env \graybox{initial_tyenv}
#{@}
\end{boxedminipage}
  \end{flushleft}
  \caption{\miniML{2} 型推論の実装 (1)}
  \label{fig:MLb1}
\end{figure}

\begin{figure}
  \begin{flushleft}
@typing.ml@: \\
  \begin{boxedminipage}{\textwidth}
#{&}
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
#{@}
\end{boxedminipage}
  \end{flushleft}
  \caption{\miniML{2} 型推論の実装 (2)}
  \label{fig:MLb2}
\end{figure}

{% endcomment %}