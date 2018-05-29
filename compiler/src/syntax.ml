open Pretty

exception Error of string
let err s = raise (Error s)

type id = string

type binOp = Plus | Mult | Lt

let string_of_op = function
    Plus -> "+"
  | Mult -> "*"
  | Lt   -> "<"

type exp =
    Var    of id
  | ILit   of int
  | BLit   of bool
  | BinOp  of binOp * exp * exp
  | IfExp  of exp * exp * exp
  | LetExp of id * exp * exp
  | AppExp of exp * exp

type decl = LetRecDecl of id * id * exp

type pgm = decl list * exp

(* ==== Formatter ==== *)

let string_of_pgm (ds, e) =
  let pr_of_op = function
      Plus -> text "+"
    | Mult -> text "*"
    | Lt   -> text "<" in
  let rec pr_of_exp p e =
    let enclose p' e = if p' < p then text "(" <*> e <*> text ")" else e in
    match e with
      Var x -> text x
    | ILit n ->
        let s = text (string_of_int n) in
        if n < 0 then text "(" <*> s <*> text ")" else s
    | BLit b -> text (string_of_bool b)
    | BinOp (op, e1, e2) ->
        enclose 2 (pr_of_exp 2 e1 <+> pr_of_op op <+> pr_of_exp 2 e2)
    | IfExp (e, e1, e2) ->
        enclose 1
          (group ((nest 2
                     (group ((text "if")
                             <+> pr_of_exp 1 e
                             <+> text "then"
                             <|> pr_of_exp 1 e1))) <|>
                  (nest 2
                     (group (text "else" <|> pr_of_exp 1 e2)))))
    | LetExp (x, e1, e2) ->
        enclose 1
          ((nest 2 (group (text "let" <+> text x <+> 
                           text "=" <|> pr_of_exp 1 e1)))
           <+> text "in" <|> pr_of_exp 1 e2)
    | AppExp (e1, e2) ->
        enclose 3 (pr_of_exp 3 e1 <+> pr_of_exp 3 e2) in
  let rec pr_of_decl (LetRecDecl (f, x, e)) =
    (group (text "let" <+> text "rec" <+>
            text f <+> text x <+>
            text "=" <|> pr_of_exp 0 e))
  in
  let dcls = match ds with
      [] -> text ""
    | d :: ds' -> (List.fold_left
                     (fun  doc decl ->
                        doc <|> text "and" <+> pr_of_decl decl)
                     (pr_of_decl d) ds') <+> text "in" in
  layout (pretty 40 (dcls <|> (pr_of_exp 0 e)))
