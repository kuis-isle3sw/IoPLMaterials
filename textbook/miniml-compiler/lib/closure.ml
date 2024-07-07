open Pretty
module S = Syntax
module N = Normal

exception Error of string

let err s = raise (Error s)

type id = S.id
type binOp = S.binOp

let fresh_id = N.fresh_id

(* ==== 値 ==== *)
type value = Var of id | IntV of int

(* ==== 式 ==== *)
type cexp =
  | ValExp of value
  | BinOp of binOp * value * value
  | AppExp of value * value list (* NEW *)
  | IfExp of value * exp * exp
  | TupleExp of value list (* NEW *)
  | ProjExp of value * int

and exp =
  | CompExp of cexp
  | LetExp of id * cexp * exp
  | LetRecExp of id * id list * exp * exp (* NEW *)
  | LoopExp of id * cexp * exp
  | RecurExp of value

(* ==== Formatter ==== *)

let string_of_closure e =
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
  let pr_of_values = function
    | [] -> text "()"
    | v :: vs' ->
        text "("
        <*> List.fold_left
              (fun d v -> d <*> text "," <+> pr_of_value v)
              (pr_of_value v) vs'
        <*> text ")"
  in
  let pr_of_ids = function
    | [] -> text "()"
    | id :: ids' ->
        text "("
        <*> List.fold_left (fun d i -> d <*> text "," <+> text i) (text id) ids'
        <*> text ")"
  in
  let rec pr_of_cexp p e =
    let enclose p' e = if p' < p then text "(" <*> e <*> text ")" else e in
    match e with
    | ValExp v -> pr_of_value v
    | BinOp (op, v1, v2) ->
        enclose 2 (pr_of_value v1 <+> pr_of_op op <+> pr_of_value v2)
    | AppExp (f, vs) -> enclose 3 (pr_of_value f <+> pr_of_values vs)
    | IfExp (v, e1, e2) ->
        enclose 1
          (nest 2
             (group
                (text "if 0 <"
                <+> pr_of_value v
                <+> text "then"
                <|> pr_of_exp 1 e1))
          <|> nest 2 (group (text "else" <|> pr_of_exp 1 e2)))
    | TupleExp vs -> pr_of_values vs
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
    | LetRecExp (id, parms, body, e) ->
        enclose 1
          (nest 2
             (group
                (text "let"
                <+> text "rec"
                <+> text id
                <+> pr_of_ids parms
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
  layout (pretty 40 (pr_of_exp 0 e))

(* entry point *)
let convert exp = CompExp (ValExp (IntV 1))
