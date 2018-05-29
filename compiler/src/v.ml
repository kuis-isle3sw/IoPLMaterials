module S = Syntax
module E = Environment

exception Error of string
let err s = raise (Error s)

type binOp = S.binOp

type offset = int
type label = string

type operand =
    Param  of int
  | Local  of offset
  | Labimm of label
  | Imm    of int

type instr =
    Move of offset * operand
  | BinOp of offset * binOp * operand * operand
  | Label of label
  | BranchIf of operand * label
  | Goto of label
  | Call of offset * operand * operand list
  | Return of operand

type decl = FunDecl of label * instr list * int

type pgm = decl list

(* ==== Formatter ==== *)

let string_of_binop = function
    S.Plus -> "add"
  | S.Mult -> "mul"
  | S.Lt   -> "lt"

let string_of_operand = function
    Param n -> "p" ^ string_of_int n
  | Local ofs -> "t" ^ string_of_int ofs
  | Labimm l -> "@" ^ l
  | Imm n -> string_of_int n

let string_of_instr idt tab = function
    Move (ofs, v) ->
      idt ^ "move" ^ tab ^ "t" ^ string_of_int ofs ^ ", " ^
      string_of_operand v
  | BinOp (ofs, op, v1, v2) ->
      idt ^ string_of_binop op ^ tab ^ "t" ^ string_of_int ofs ^ ", " ^
      string_of_operand v1 ^ ", " ^ string_of_operand v2
  | Label l -> l ^ ":"
  | BranchIf (v, l) ->
      idt ^ "bif" ^ tab ^ string_of_operand v ^ ", " ^ l
  | Goto l ->
      idt ^ "goto" ^ tab ^ l
  | Call (ofs, f, [v]) ->
      idt ^ "call" ^ tab ^ "t" ^ string_of_int ofs ^ ", " ^
      string_of_operand f ^
      "(" ^ string_of_operand v ^ ")"
  | Call (_, _, vs) ->
      err ("Illegal number of arguments: " ^
           string_of_int (List.length vs))
  | Return v ->
      idt ^ "ret" ^ tab ^ string_of_operand v

let string_of_decl (FunDecl (l, is, n)) =
  "fun " ^ l ^ "[" ^ string_of_int n ^ "] =\n" ^
  String.concat "\n" (List.map
                        (fun i -> string_of_instr "  " "\t" i)
                        is)

let string_of_pgm ds  = String.concat "\n" (List.map string_of_decl ds)

(* ==== Conversion from C ==== *)

let offset_of = function
    Local ofs -> ofs
  | _ -> err "offset_of must be called for local."

let rec bound_vars = function
    C.IfExp (_, e1, e2) -> bound_vars e1 @ bound_vars e2
  | C.LetExp (id, e1, e2) -> id :: bound_vars e1 @ bound_vars e2
  | _ -> []

let extend_locals env e =
  let bvs = bound_vars e in
  let ofs_bvs = List.mapi (fun i x -> (x, 4*(i+1))) bvs in
  (4 * (List.length bvs + 1),
   List.fold_right (fun (x, ofs) e -> E.extend x (Local ofs) e) ofs_bvs env)

let vt_decl fenv (C.LetRecDecl (fname, parm, body)) =
  let fresh_label =
    let fi = Misc.fresh_id_maker "L" in
    fun () -> fi (fname ^ "_")
  in
  let rec vt_exp env tgt = function
      C.Var x -> [Move (offset_of tgt, E.lookup x env)]
    | C.IntV n -> [Move (offset_of tgt, Imm n)]
    | C.BoolV true -> [Move (offset_of tgt, Imm 1)]
    | C.BoolV false -> [Move (offset_of tgt, Imm 0)]
    | C.BinOp (op, x1, x2) ->
        [BinOp (offset_of tgt, op, E.lookup x1 env, E.lookup x2 env)]
    | C.IfExp (x, e1, e2) ->
        let ltrue = fresh_label () in
        let lend = fresh_label () in
        [BranchIf (E.lookup x env, ltrue)] @
        vt_exp env tgt e2 @
        [Goto lend; Label ltrue] @
        vt_exp env tgt e1 @
        [Label lend]
    | C.LetExp (x, e1, e2) ->
        vt_exp env (E.lookup x env) e1 @
        vt_exp env tgt e2
    | C.AppExp (x1, x2) ->
        [Call (offset_of tgt, E.lookup x1 env, [E.lookup x2 env])]
  in
  let env = E.extend parm (Param 1) fenv in
  let (max_ofs, env') = extend_locals env body in
  FunDecl (fname, vt_exp env' (Local 0) body @ [Return (Local 0)], max_ofs)

(* entry point *)
let vt ds =
  let fs = List.map (fun (C.LetRecDecl (f, _, _)) -> f) ds in
  let fenv = 
    List.fold_right (fun f e -> E.extend f (Labimm f) e) fs E.empty in
  List.map (fun d -> vt_decl fenv d) ds
