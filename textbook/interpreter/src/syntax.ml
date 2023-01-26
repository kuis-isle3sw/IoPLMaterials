(* ML interpreter / type reconstruction *)
type id = string [@@deriving show]
type binOp = Plus | Mult | Lt | And | Or [@@deriving show]

type exp =
  | Var of id
  | ILit of int
  | BLit of bool
  | BinOp of binOp * exp * exp
  | IfExp of exp * exp * exp
  | LetExp of (id * exp) list * exp
  | FunExp of id * exp
  | DFunExp of id * exp
  | AppExp of exp * exp
[@@deriving show]

type program = Exp of exp | Decls of (id * exp) list list [@@deriving show]
type tyvar = int [@@deriving show]

type ty = TyInt | TyBool | TyVar of tyvar | TyFun of ty * ty | TyList of ty
[@@deriving show]
