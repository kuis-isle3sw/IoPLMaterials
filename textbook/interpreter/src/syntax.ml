(* ML interpreter / type reconstruction *)
type id = string
type binOp = Plus | Mult | Lt | And | Or

type exp =
  | Var of id
  | ILit of int
  | BLit of bool
  | BinOp of binOp * exp * exp
  | IfExp of exp * exp * exp
  | LetExp of id * exp * exp

type program = Exp of exp | Decl of id * exp
type tyvar = int
type ty = TyInt | TyBool | TyVar of tyvar | TyFun of ty * ty | TyList of ty
