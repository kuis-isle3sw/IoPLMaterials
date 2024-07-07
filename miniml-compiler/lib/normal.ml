open Pretty
module S = Syntax

exception Error of string

let err s = raise (Error s)

type id = S.id
type binOp = S.binOp

let fresh_id = Misc.fresh_id_maker "_"

(* ==== 値 ==== *)
type value = Var of id | IntV of int

(* ==== 式 ==== *)
type cexp =
  | ValExp of value
  | BinOp of binOp * value * value
  | AppExp of value * value
  | IfExp of value * exp * exp
  | TupleExp of value * value
  | ProjExp of value * int

and exp =
  | CompExp of cexp
  | LetExp of id * cexp * exp
  | LetRecExp of id * id * exp * exp
  | LoopExp of id * cexp * exp
  | RecurExp of value

(* ==== Formatter ==== *)

let string_of_norm e =
  let pr_of_op = function
    | S.Plus -> text "+"
    | S.Mult -> text "*"
    | S.Lt -> text "<"
  in
  let pr_of_value = function
    | Var id -> text id
    | IntV i ->
        let s = text (string_of_int i) in
        if i < 0 then text "(" <*> s <*> text ")" else s
  in
  let rec pr_of_cexp p e =
    let enclose p' e = if p' < p then text "(" <*> e <*> text ")" else e in
    match e with
    | ValExp v -> pr_of_value v
    | BinOp (op, v1, v2) ->
        enclose 2 (pr_of_value v1 <+> pr_of_op op <+> pr_of_value v2)
    | AppExp (f, v) -> enclose 3 (pr_of_value f <+> pr_of_value v)
    | IfExp (v, e1, e2) ->
        enclose 1
          (nest 2
             (group
                (text "if 0 <"
                <+> pr_of_value v
                <+> text "then"
                <|> pr_of_exp 1 e1))
          <|> nest 2 (group (text "else" <|> pr_of_exp 1 e2)))
    | TupleExp (v1, v2) ->
        text "(" <*> pr_of_value v1 <*> text "," <+> pr_of_value v2 <*> text ")"
    | ProjExp (v, i) ->
        enclose 2 (pr_of_value v <*> text "." <*> text (string_of_int i))
  and pr_of_exp p e =
    let enclose p' e = if p' < p then text "(" <*> e <*> text ")" else e in
    match e with
    | CompExp ce -> pr_of_cexp p ce
    | LetExp (id, ce, e) ->
        enclose 1
          (nest 2
             (group (text "let" <+> text id <+> text "=" <|> pr_of_cexp 1 ce))
          <+> text "in"
          <|> pr_of_exp 1 e)
    | LetRecExp (id, v, body, e) ->
        enclose 1
          (nest 2
             (group
                (text "let"
                <+> text "rec"
                <+> text id
                <+> text v
                <+> text "="
                <|> pr_of_exp 1 body))
          <+> text "in"
          <|> pr_of_exp 1 e)
    | LoopExp (id, ce, e) ->
        enclose 1
          (nest 2
             (group (text "loop" <+> text id <+> text "=" <|> pr_of_cexp 1 ce))
          <+> text "in"
          <|> pr_of_exp 1 e)
    | RecurExp v -> enclose 3 (text "recur" <+> pr_of_value v)
  in
  layout (pretty 30 (pr_of_exp 0 e))

(* ==== 正規形への変換 ==== *)

let rec norm_exp (e : Syntax.exp) (f : cexp -> exp) =
  (* TODO *)
  match e with _ -> f (ValExp (IntV 1))

and normalize e = norm_exp e (fun ce -> CompExp ce)

(* ==== entry point ==== *)
let convert prog = normalize prog
