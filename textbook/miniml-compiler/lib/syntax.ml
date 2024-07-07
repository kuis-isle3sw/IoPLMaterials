exception Error of string

let err s = raise (Error s)

type id = string
type binOp = Plus | Mult | Lt

type exp =
  | Var of id
  | ILit of int
  | BLit of bool
  | BinOp of binOp * exp * exp
  | IfExp of exp * exp * exp
  | LetExp of id * exp * exp
  | FunExp of id * exp
  | AppExp of exp * exp
  | LetRecExp of id * id * exp * exp
  | LoopExp of id * exp * exp (* loop <id> = <exp> in <exp> *)
  | RecurExp of exp (* recur <exp> *)
  | TupleExp of exp * exp (* (<exp>, <exp>) *)
  | ProjExp of exp * int (* <exp> . <int> *)

(* ==== recur式が末尾位置にのみ書かれていることを検査 ==== *)

let recur_check e = ()
