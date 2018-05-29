open Pretty
module S = Syntax
module E = Environment

exception Error of string
let err s = raise (Error s)

type id = S.id
type binOp = S.binOp

let fresh_id = Misc.fresh_id_maker "_"

type exp =
    Var    of id
  | IntV   of int
  | BoolV  of bool
  | BinOp  of binOp * id * id
  | IfExp  of id * exp * exp
  | LetExp of id * exp * exp
  | AppExp of id * id

type decl = LetRecDecl of id * id * exp

type pgm = decl list

(* ==== Formatter ==== *)

let string_of_pgm ds =
  let pr_of_op = function
      S.Plus -> text "+"
    | S.Mult -> text "*"
    | S.Lt   -> text "<" in
  let rec pr_of_exp p e =
    let enclose p' e = if p' < p then text "(" <*> e <*> text ")" else e in
    match e with
      Var x -> text x
    | IntV n ->
        let s = text (string_of_int n) in
        if n < 0 then text "(" <*> s <*> text ")" else s
    | BoolV b -> text (string_of_bool b)
    | BinOp (op, x1, x2) ->
        enclose 2 (text x1 <+> pr_of_op op <+> text x2)
    | IfExp (x, e1, e2) ->
        enclose 1
          (group ((nest 2
                     (group ((text "if") <+> text x <+> text "then"
                             <|> pr_of_exp 1 e1))) <|>
                  (nest 2
                     (group (text "else" <|> pr_of_exp 1 e2)))))
    | LetExp (x, e1, e2) ->
        enclose 1
          ((nest 2 (group (text "let" <+> text x <+> 
                           text "=" <|> pr_of_exp 1 e1)))
           <+> text "in" <|> pr_of_exp 1 e2)
    | AppExp (x1, x2) ->
        enclose 3 (text x1 <+> text x2) in
  let rec pr_of_decl (LetRecDecl (f, x, e)) =
    (nest 2 (group (text "let" <+> text "rec" <+>
                    text f <+> text x <+> text "=" <|>
                    pr_of_exp 0 e)))
  in
  let dcls = match ds with
      [] -> text ""
    | d :: ds' -> (List.fold_left
                     (fun  doc decl ->
                        doc <|> text "and" <+> pr_of_decl decl)
                     (pr_of_decl d) ds') <+> text "in"
  in layout (pretty 40 dcls)

(* ==== Conversion from AST ==== *)

let rec i_of_exp env e = match e with
    S.Var x -> Var (E.lookup x env)
  | S.ILit n -> IntV n
  | S.BLit b -> BoolV b
  | S.BinOp (op, e1, e2) ->
      let x1 = fresh_id "x" in
      let x2 = fresh_id "x" in
      LetExp (x1, i_of_exp env e1,
              LetExp (x2, i_of_exp env e2,
                      BinOp (op, x1, x2)))
  | S.IfExp (e, e1, e2) ->
      let x = fresh_id "x" in
      LetExp (x, i_of_exp env e,
              IfExp (x, i_of_exp env e1, i_of_exp env e2))
  | S.LetExp (x, e1, e2) ->
      let t1 = fresh_id x in
      LetExp (t1, i_of_exp env e1,
              i_of_exp (E.extend x t1 env) e2)
  | S.AppExp (e1, e2) ->
      let x1 = fresh_id "x" in
      let x2 = fresh_id "x" in
      LetExp (x1, i_of_exp env e1,
              LetExp (x2, i_of_exp env e2,
                      AppExp (x1, x2)))

let i_of_decl env (S.LetRecDecl (f, x, e)) =
  let t1 = fresh_id x in
  LetRecDecl (E.lookup f env, t1, i_of_exp (E.extend x t1 env) e)

let i_of_pgm (ds, e) =
  let ds' = ds @ [S.LetRecDecl ("_toplevel", fresh_id "p", e)] in
  let env =
    List.fold_right
      (fun (S.LetRecDecl (f, _, _)) e -> E.extend f f e) ds' E.empty in
  List.map (fun d -> i_of_decl env d) ds'
