{% include head.html %}

# MiniML3,4 のための型推論 (3): 型推論アルゴリズムの実装

ここまでの話を総合すると，MiniML3 のための型推論アルゴリズムが得られる．例えば，$e_1 + e_2$ 式に対する型推論は，$\textrm{T-Plus}$ 規則を下から上に読むと，

- $\Gamma, e_1$ を入力として型推論を行い，$\theta_1$，$\tau_1$ を得る．
- $\Gamma, e_2$ を入力として型推論を行い，$\theta_2$，$\tau_2$ を得る．
- 型代入 $\theta_1, \theta_2$ を $\alpha = \tau$ という形の方程式の集まりとみなして， $\theta_1 \cup \theta_2 \cup \\{\tau_1 = \mathbf{int}, \tau_2 = \mathbf{int}\\}$ を単一化し，型代入$\theta_3$を得る．
- $\theta_3$ と $\mathbf{int}$ を出力として返す．

となる．部分式の型推論で得られた型代入を方程式とみなして，再び単一化を行うのは，ひとつの部分式から $[\alpha \mapsto \tau_1]$，もうひとつからは $[\alpha \mapsto \tau_2]$ という代入が得られた時に$\tau_1$ と$\tau_2$ の整合性が取れているか（単一化できるか）を検査するためである．

### Exercise 4.3.5 [必修]
他の型付け規則に関しても同様に型推論の手続きを与えよ(レポートの一部としてまとめよ)．そして，以下の `typing.ml` に加えるべき変更の解説を参考にして，型推論アルゴリズムの実装を完成させよ．

{% highlight ocaml %}
(* New! 型代入を表す値の型 *)
type subst = (tyvar * ty) list

(* すでに実装済みのはず *)
let rec subst_type subst t = ...

(* New! eqs_of_subst : subst -> (ty * ty) list
   型代入を型の等式集合に変換．型の等式制約 ty1 = ty2 は (ty1,ty2) という
   ペアで表現し，等式集合はペアのリストで表現． *)
let eqs_of_subst s = ... 

(* New! 
   subst_eqs: subst -> (ty * ty) list -> (ty * ty) list
   型の等式集合に型代入を適用する関数． *)
let subst_eqs s eqs = ...

(* すでに実装済みのはず *)
let rec unify l = ... 

(* New! 演算子 op が生成すべき制約集合と返り値の型を記述 *)
let ty_prim op ty1 ty2 = match op with
    Plus -> ([(ty1, TyInt); (ty2, TyInt)], TyInt)
  | ...

(* New! 型環境 tyenv と式 exp を受け取って，型代入と exp の型のペアを返す *)
let rec ty_exp tyenv exp =
  match exp with
    Var x ->
     (try ([], Environment.lookup x tyenv) with
         Environment.Not_bound -> err ("variable not bound: " ^ x))
  | ILit _ -> ([], TyInt)
  | BLit _ -> ([], TyBool)
  | BinOp (op, exp1, exp2) ->
      let (s1, ty1) = ty_exp tyenv exp1 in
      let (s2, ty2) = ty_exp tyenv exp2 in
      let (eqs3, ty) = ty_prim op ty1 ty2 in
	  (* s1 と s2 を等式制約の集合に変換して，eqs3 と合わせる *)
      let eqs = (eqs_of_subst s1) @ (eqs_of_subst s2) @ eqs3 in
	  (* 全体の制約をもう一度解く．*)
      let s3 = unify eqs in (s3, subst_type s3 ty)
  | IfExp (exp1, exp2, exp3) -> ...
  | LetExp (id, exp1, exp2) -> ...
  | FunExp (id, exp) ->
      (* id の型を表す fresh な型変数を生成 *)
      let domty = TyVar (fresh_tyvar ()) in
	  (* id : domty で tyenv を拡張し，その下で exp を型推論 *)
      let s, ranty =
        ty_exp (Environment.extend id domty tyenv) exp in
        (s, TyFun (subst_type s domty, ranty))
  | AppExp (exp1, exp2) -> ...
  | _ -> Error.typing ("Not Implemented!")
{% endhighlight %}

### Exercise 4.3.6 [**]
再帰的定義のための `let rec` 式の型付け規則は以下のように与えられる．

$$
\begin{array}{c}
\Gamma, f: \tau_1 \rightarrow \tau_2, x: \tau_1 \vdash e_1 : \tau_2 \quad
\Gamma, f:\tau_1 \rightarrow \tau_2 \vdash e_2 : \tau\\
\rule{13cm}{1pt}\\
\Gamma \vdash \mathbf{let\ rec}\ f = \mathbf{fun}\ x\ \rightarrow e_1\ \mathbf{in}\ e_2 : \tau
\end{array}
\textrm{T-LetRec}
$$

型推論アルゴリズムが `let rec` 式を扱えるように拡張せよ．



### Exercise 4.3.7 [**]

以下は，リスト操作に関する式の型付け規則である．リストには要素の型を $\tau$ として $\tau\ \mathbf{list}$ という型を与える．型推論アルゴリズムがこれらの式を扱えるように拡張せよ．

#### T-Nil

$$
\begin{array}{c}
\rule{6cm}{1pt}\\
\Gamma \vdash [] : \tau\ \mathbf{list}
\end{array}
\textrm{T-Nil}
$$

#### T-Cons

$$
\begin{array}{c}
\Gamma \vdash e_1 : \tau \quad
\Gamma \vdash e_2 : \tau\ \mathbf{list}\\
\rule{6cm}{1pt}\\
\Gamma \vdash e_1 :: e_2 : \tau\ \mathbf{list}
\end{array}
\textrm{T-Cons}
$$

#### T-Match

$$
\begin{array}{c}
\Gamma \vdash e : \tau_1\ \mathbf{list} \quad
\Gamma \vdash e_1 : \tau_2 \quad
\Gamma, x : \tau_1, y : \tau_1\ \mathbf{list} \vdash e_2 : \tau_2\\
\rule{20cm}{1pt}\\
	\Gamma \vdash \mathbf{match}\ e\ \mathbf{with}\ [] \rightarrow e_1 \mid x :: y \rightarrow e_2 : \tau_2
\end{array}
\textrm{T-Cons}
$$


