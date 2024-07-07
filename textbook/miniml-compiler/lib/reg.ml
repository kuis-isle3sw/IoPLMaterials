exception Error of string

let err s = raise (Error s)

type binOp = Vm.binOp
type offset = int
type label = string
type reg = int (* 汎用レジスタ．0以上の整数 *)

(* コード生成が swap に利用するための専用レジスタ．
   実際にどの物理レジスタを用いるかはアーキテクチャ依存 *)
let reserved_reg = -1

type dest =
  (* レジスタ *)
  | R of reg
  (* 局所領域の関数フレーム中の相対位置 *)
  | L of offset

type operand = Param of int | Reg of reg | Proc of label | IntV of int

type instr =
  | Move of reg * operand
  | Load of reg * offset
  | Store of reg * offset
  | BinOp of reg * Vm.binOp * operand * operand
  | Label of label
  | BranchIf of operand * label
  | Goto of label
  | Call of dest * operand * operand list
  | Return of operand
  | Malloc of dest * operand list
  | Read of dest * operand * int

type decl = ProcDecl of label * int * instr list (* int: 局所領域の個数 *)
type prog = decl list

(* Formatter *)

let string_of_binop = function
  | Syntax.Plus -> "add"
  | Syntax.Mult -> "mul"
  | Syntax.Lt -> "lt"

let string_of_dest = function
  | R r -> "r" ^ string_of_int r
  | L oft -> "t" ^ string_of_int oft

let string_of_operand = function
  | Param i -> "p" ^ string_of_int i
  | Reg r -> "r" ^ string_of_int r
  | Proc l -> l
  | IntV i -> string_of_int i

let string_of_instr idt tab = function
  | Move (t, v) ->
      idt ^ "move" ^ tab ^ "r" ^ string_of_int t ^ ", " ^ string_of_operand v
  | Load (r, oft) ->
      idt ^ "load" ^ tab ^ "r" ^ string_of_int r ^ ", t" ^ string_of_int oft
  | Store (r, oft) ->
      idt ^ "store" ^ tab ^ "r" ^ string_of_int r ^ ", t" ^ string_of_int oft
  | BinOp (t, op, v1, v2) ->
      idt
      ^ string_of_binop op
      ^ tab
      ^ "r"
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
      ^ string_of_dest dst
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
      ^ string_of_dest t
      ^ " ["
      ^ String.concat ", " (List.map string_of_operand vs)
      ^ "]"
  | Read (t, v, i) ->
      idt
      ^ "read"
      ^ tab
      ^ string_of_dest t
      ^ " #"
      ^ string_of_int i
      ^ "("
      ^ string_of_operand v
      ^ ")"

let string_of_decl (ProcDecl (lbl, n, instrs)) =
  "proc "
  ^ lbl
  ^ "("
  ^ string_of_int n
  ^ ") =\n"
  ^ String.concat "\n" (List.map (fun i -> string_of_instr "  " "\t" i) instrs)
  ^ "\n"

let string_of_reg prog = String.concat "\n" (List.map string_of_decl prog)

(* ==== レジスタ割付け ==== *)

let trans_decl nreg lives (Vm.ProcDecl (lbl, nlocal, instrs)) =
  let insts' = [ Return (IntV 1) ] in
  ProcDecl (lbl, 0, insts')

(* entry point *)
let trans nreg lives = List.map (trans_decl nreg lives)
