module S = Syntax
module F = Flat

exception Error of string

let err s = raise (Error s)

type binOp = S.binOp
type id = int
type label = string

type operand =
  | Param of int (* param(n) *)
  | Local of id (* local(ofs) *)
  | Proc of label (* labimm(l) *)
  | IntV of int (* imm(n) *)

type instr =
  | Move of id * operand (* local(ofs) <- op *)
  | BinOp of id * S.binOp * operand * operand
    (* local(ofs) <- bop(op_1, op_2) *)
  | Label of label (* l: *)
  | BranchIf of operand * label (* if op then goto l *)
  | Goto of label (* goto l *)
  | Call of id * operand * operand list
    (* local(ofs) <- call op_f(op_1, ..., op_n) *)
  | Return of operand (* return(op) *)
  | Malloc of id * operand list (* new ofs [op_1, ..., op_n] *)
  | Read of id * operand * int (* read ofs #i(op) *)
  | BEGIN of label (* データフロー解析で内部的に使用 *)
  | END of label (* データフロー解析で内部的に使用 *)

type decl = ProcDecl of label * int * instr list (* int は局所変数の個数 *)
type prog = decl list

(* ==== Formatter ==== *)

let string_of_binop = function
  | S.Plus -> "add"
  | S.Mult -> "mul"
  | S.Lt -> "lt"

let string_of_operand = function
  | Param i -> "p" ^ string_of_int i
  | Local o ->
      (* -1 は生存変数解析で使われる特殊な値 *)
      if o = -1 then "*" else "t" ^ string_of_int o
  | Proc l -> l
  | IntV i -> string_of_int i

let string_of_instr idt tab = function
  | Move (t, v) ->
      idt ^ "move" ^ tab ^ "t" ^ string_of_int t ^ ", " ^ string_of_operand v
  | BinOp (t, op, v1, v2) ->
      idt
      ^ string_of_binop op
      ^ tab
      ^ "t"
      ^ string_of_int t
      ^ ", "
      ^ string_of_operand v1
      ^ ", "
      ^ string_of_operand v2
  | Label lbl -> lbl ^ ":"
  | BranchIf (v, lbl) -> idt ^ "bif" ^ tab ^ string_of_operand v ^ ", " ^ lbl
  | Goto lbl -> idt ^ "goto" ^ tab ^ lbl
  | Call (dst, tgt, [ a0; a1 ]) ->
      idt
      ^ "call"
      ^ tab
      ^ "t"
      ^ string_of_int dst
      ^ ", "
      ^ string_of_operand tgt
      ^ "("
      ^ string_of_operand a0
      ^ ", "
      ^ string_of_operand a1
      ^ ")"
  | Call (_, _, args) ->
      err ("Illegal number of arguments: " ^ string_of_int (List.length args))
  | Return v -> idt ^ "ret" ^ tab ^ string_of_operand v
  | Malloc (t, vs) ->
      idt
      ^ "new"
      ^ tab
      ^ "t"
      ^ string_of_int t
      ^ " ["
      ^ String.concat ", " (List.map string_of_operand vs)
      ^ "]"
  | Read (t, v, i) ->
      idt
      ^ "read"
      ^ tab
      ^ "t"
      ^ string_of_int t
      ^ " #"
      ^ string_of_int i
      ^ "("
      ^ string_of_operand v
      ^ ")"
  | BEGIN lbl -> idt ^ "<BEGIN: " ^ lbl ^ ">"
  | END lbl -> idt ^ "<END: " ^ lbl ^ ">"

let string_of_decl (ProcDecl (lbl, n, instrs)) =
  "proc "
  ^ lbl
  ^ "("
  ^ string_of_int n
  ^ ") =\n"
  ^ String.concat "\n" (List.map (fun i -> string_of_instr "  " "\t" i) instrs)
  ^ "\n"

let string_of_vm prog = String.concat "\n" (List.map string_of_decl prog)

(* ==== 仮想機械コードへの変換 ==== *)

let trans_decl (F.RecDecl (proc_name, params, body)) =
  ProcDecl (proc_name, 1, [ Move (0, IntV 1); Return (Local 0) ])

(* entry point *)
let trans = List.map trans_decl
