{% include head.html %}

# MiniML3,4 のための型推論 (3): 型推論アルゴリズムの実装

ここまでの話を総合すると，MiniML3 のための型推論アルゴリズムが得られる．例えば，$e_1 + e_2$ 式に対する型推論は，\textrm{T-Plus}規則を下から上に読むと，

- $\Gamma, e_1$ を入力として型推論を行い，$\theta_1$，$\tau_1$ を得る．
- $\Gamma, e_2$ を入力として型推論を行い，$\theta_2$，$\tau_2$ を得る．
- 型代入 $\theta_1, \theta_2$ を $\alpha = \tau$ という形の方程式の集まりとみなして，$\theta_1 \cup \theta_2 \cup \{\tau_1 = \mathbf{int}, (\tau_2, \mathbf{int})\}$ を単一化し，型代入$\theta_3$を得る．
- $\theta_3$ と $\mathbf{int}$ を出力として返す．

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
  \caption{MiniML3 型推論の実装(2)}
  \label{fig:MLarrow2}
\end{figure}

