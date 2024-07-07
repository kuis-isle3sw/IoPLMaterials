module S = Syntax
open Arm_spec

exception Error of string

let err s = raise (Error s)

(* ==== メモリアクセス関連 ==== *)

(* 「reg中のアドレスからoffsetワード目」をあらわすaddr *)
let mem_access reg offset = RI (reg, offset * 4)
let local_access i = mem_access Fp (-i - 2)

(* Vm.Param は 0 から数えるものと仮定 *)
let param_to_reg = function
  | 0 -> A1
  | 1 -> A2
  | i -> err ("invalid parameter: " ^ string_of_int i)

(* Vm.operandから値を取得し，レジスタrdに格納するような
   stmt listを生成 *)
let gen_operand rd = function
  | Vm.Param i ->
      let rs = param_to_reg i in
      if rd = rs then [] else [ Instr (Mov (rd, R rs)) ]
  | Vm.Local i -> [ Instr (Ldr (rd, local_access i)) ]
  | Vm.Proc lbl -> [ Instr (Ldr (rd, L lbl)) ]
  | Vm.IntV i -> [ Instr (Mov (rd, I i)) ]

(* ==== 仮想マシンコード --> アセンブリコード ==== *)

(* V.decl -> loc list *)
let gen_decl (Vm.ProcDecl (name, nlocal, instrs)) =
  [
    Dir (D_align 2);
    Dir (D_global name);
    Label name;
    Instr (Mov (A1, I 1));
    Label (name ^ "_ret");
    Instr (Bx Lr);
  ]

(* entry point: Vm.decl list -> stmt list *)
let codegen vmprog = Dir D_text :: List.concat (List.map gen_decl vmprog)
