open Syntax

type exval =
  | IntV of int
  | BoolV of bool
  | ProcV of id * exp * dnval Environment.t
  | DProcV of id * exp
[@@deriving show]

and dnval = exval [@@deriving show]

exception Error of string

let err s = raise (Error s)

(* pretty printing *)
let rec string_of_exval = function
  | IntV i -> string_of_int i
  | BoolV b -> string_of_bool b
  | ProcV _ -> "<fun>"
  | DProcV _ -> "<dfun>"

let pp_val v = print_string (string_of_exval v)

let rec apply_prim op arg1 arg2 =
  match (op, arg1, arg2) with
  | Plus, IntV i1, IntV i2 -> IntV (i1 + i2)
  | Plus, _, _ -> err "Both arguments must be integer: +"
  | Mult, IntV i1, IntV i2 -> IntV (i1 * i2)
  | Mult, _, _ -> err "Both arguments must be integer: *"
  | Lt, IntV i1, IntV i2 -> BoolV (i1 < i2)
  | Lt, _, _ -> err "Both arguments must be integer: <"
  | And, BoolV b1, BoolV b2 -> BoolV (b1 && b2)
  | And, _, _ -> err "Both arguments must be bool: &&"
  | Or, BoolV b1, BoolV b2 -> BoolV (b1 || b2)
  | Or, _, _ -> err "Both arguments must be bool: ||"

let rec eval_exp env = function
  | Var x -> (
      try Environment.lookup x env
      with Environment.Not_bound -> err ("Unbounded value " ^ x))
  | ILit i -> IntV i
  | BLit b -> BoolV b
  | BinOp (op, exp1, exp2) ->
      let arg1 = eval_exp env exp1 in
      let arg2 = eval_exp env exp2 in
      apply_prim op arg1 arg2
  | IfExp (exp1, exp2, exp3) -> (
      let test = eval_exp env exp1 in
      match test with
      | BoolV true -> eval_exp env exp2
      | BoolV false -> eval_exp env exp3
      | _ -> err "Test expression must be boolean: if")
  | LetExp (bindings, exp2) ->
      let newenv =
        bindings
        |> List.map (fun (id, exp) -> (id, eval_exp env exp))
        |> List.fold_left
             (fun newenv (id, v) -> Environment.extend id v newenv)
             env
      in
      eval_exp newenv exp2
  | FunExp (id, exp) -> ProcV (id, exp, env)
  | DFunExp (id, exp) -> DProcV (id, exp)
  | AppExp (exp1, exp2) -> (
      let funval = eval_exp env exp1 in
      let arg = eval_exp env exp2 in
      match funval with
      | ProcV (id, body, env') ->
          let newenv = Environment.extend id arg env' in
          eval_exp newenv body
      | DProcV (id, body) ->
          let newenv = Environment.extend id arg env in
          eval_exp newenv body
      | _ -> err "Non-function value is applied")

let eval_program env = function
  | Exp e ->
      let v = eval_exp env e in
      ([ ("-", v) ], env)
  | Decls decls ->
      let defs, newenv =
        List.fold_left
          (fun (defs, newenv) bindings ->
            (* NOTE:
               In the original, variables of the same name cannot be defined using `and`,
               but are assumed to be definable here for simplicity. *)
            let newdefs =
              bindings |> List.map (fun (id, e) -> (id, eval_exp newenv e))
            in
            ( List.rev_append newdefs defs,
              List.fold_left
                (fun newenv (id, v) -> Environment.extend id v newenv)
                newenv newdefs ))
          ([], env) decls
      in
      (* NOTE: Sort by declaration *)
      (List.rev defs, newenv)
