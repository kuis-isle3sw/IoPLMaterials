module S = Syntax
open Arm_spec

exception Error of string
let err s = raise (Error s)

(* ==== メモリアクセス関連 ==== *)

(* Reg.reg -> reg *)
let reg_mappings = [
  (Reg.reserved_reg, Ip);
  (0, V1);
  (1, V2);
  (2, V3);
  (3, V4);
  (4, V5);
  (5, V6);
  (6, V7);
]

let reg_of r = List.assoc r reg_mappings

(* 「reg中のアドレスからoffsetワード目」をあらわすaddr *)
let mem_access reg offset = RI (reg, offset*4)

let local_access i = mem_access Fp (-i-2)

let param_to_reg = function
    0 -> A1
  | 1 -> A2
  | i -> err ("invalid parameter: " ^ string_of_int i)

(* Reg.operand から値を取得し，レジスタrdに格納するような
   stmt listを生成 *)
let gen_operand rd = function
    Reg.Param i ->
      let rs = param_to_reg i in
      if rd = rs then [] else [Instr (Mov (rd, R rs))]
  | Reg.Reg r ->
      let rs = reg_of r in
      if rd = rs then [] else [Instr (Mov (rd, R rs))]
  | Reg.Proc lbl -> [Instr (Ldr (rd, L lbl))]
  | Reg.IntV i -> [Instr (Mov (rd, I i))]

(* ==== Regマシンコード --> アセンブリコード ==== *)

let gen_decl (Reg.ProcDecl(name, nlocal, instrs)) =
  [Dir (D_align 2);
   Dir (D_global name);
   Label name;
   Instr (Mov (A1, I 1));
   Label (name ^ "_ret");
   Instr (Bx Lr)]

let codegen regprog =
  Dir D_text :: List.concat (List.map gen_decl regprog)
