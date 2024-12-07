(* ==== ARM命令セット仕様 ==== *)

(* ==== 即値，ラベル ==== *)
type imm = int
type label = string

(* ==== レジスタ ==== *)
let nreg = 7 (* 使用する汎用レジスタの個数 *)

type reg =
  | A1 (* 1st parameter & return value *)
  | A2 (* 2nd parameter *)
  | A3 (* 3rd parameter *)
  | A4 (* 4th parameter *)
  | V1
  | V2
  | V3
  | V4
  | V5
  | V6
  | V7
  | Fp (* frame pointer *)
  | Ip (* intra-procedural call register *)
  | Sp (* stack pointer *)
  | Lr

(* link register (return address) *)
(* | Pc (* program counter *) *)

(* ==== アドレッシング・モード ==== *)
type addr =
  | I of imm (* 即値(Immediate) *)
  | R of reg (* レジスタ(Register) *)
  | L of label (* ラベル(Label) *)
  | RI of reg * imm (* レジスタ間接(Register Indirect) *)

(* ==== 命令 ==== *)
type instr =
  | Add of reg * reg * addr
  | B of label
  | Bl of label
  | Blt of label
  | Blx of reg
  | Bne of label
  | Bx of reg
  | Cmp of reg * addr
  | Ldr of reg * addr
  | Mov of reg * addr (* レジスタ同士にも即値ロードにも *)
  | Mul of reg * reg * reg
  | Str of reg * addr
  | Sub of reg * reg * addr

(* ==== アセンブラ指示子 ==== *)
type directive =
  | D_align of int
  | D_global of string
  | D_text

type stmt =
  | Dir of directive
  | Label of label
  | Instr of instr

let string_of_reg r =
  match r with
  | A1 -> "a1"
  | A2 -> "a2"
  | A3 -> "a3"
  | A4 -> "a4"
  | V1 -> "v1"
  | V2 -> "v2"
  | V3 -> "v3"
  | V4 -> "v4"
  | V5 -> "v5"
  | V6 -> "v6"
  | V7 -> "v7"
  | Fp -> "fp"
  | Ip -> "ip"
  | Sp -> "sp"
  | Lr -> "lr"
;;

(* | Pc -> "pc" *)

let string_of_addr = function
  | I i -> "#" ^ string_of_int i
  | R r -> string_of_reg r
  | L lbl -> lbl
  | RI (r, i) -> Printf.sprintf "[%s, #%d]" (string_of_reg r) i
;;

let string_of_instr instr =
  let emit_instr op rands = op ^ "\t" ^ String.concat ", " rands in
  match instr with
  | Add (r1, r2, a) ->
    emit_instr "add" [ string_of_reg r1; string_of_reg r2; string_of_addr a ]
  | B lbl -> emit_instr "b" [ lbl ]
  | Bl lbl -> emit_instr "bl" [ lbl ]
  | Blt lbl -> emit_instr "blt" [ lbl ]
  | Blx r -> emit_instr "blx" [ string_of_reg r ]
  | Bne lbl -> emit_instr "bne" [ lbl ]
  | Bx r -> emit_instr "bx" [ string_of_reg r ]
  | Cmp (r, a) -> emit_instr "cmp" [ string_of_reg r; string_of_addr a ]
  | Ldr (r, a) ->
    let str_of_addr =
      match a with
      | L l -> "=" ^ l
      | _ -> string_of_addr a
    in
    emit_instr "ldr" [ string_of_reg r; str_of_addr ]
  | Mov (r, a) -> emit_instr "mov" [ string_of_reg r; string_of_addr a ]
  | Mul (r1, r2, r3) ->
    emit_instr "mul" [ string_of_reg r1; string_of_reg r2; string_of_reg r3 ]
  | Str (r, a) -> emit_instr "str" [ string_of_reg r; string_of_addr a ]
  | Sub (r1, r2, a) ->
    emit_instr "sub" [ string_of_reg r1; string_of_reg r2; string_of_addr a ]
;;

let string_of_directive = function
  | D_align i -> "align " ^ string_of_int i
  | D_global s -> "global " ^ s
  | D_text -> "text"
;;

let string_of_stmt = function
  | Instr i -> "\t" ^ string_of_instr i
  | Label lbl -> lbl ^ ":"
  | Dir d -> "\t." ^ string_of_directive d
;;

let string_of prog = String.concat "\n" (List.map string_of_stmt prog)
