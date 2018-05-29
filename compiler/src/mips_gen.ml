open Mips_spec
module S = Syntax

exception Error of string
let err s = raise (Error s)

(* ==== system call ==== *)

let syscall s =
  [Instr (Li (V0, syscall_to_num s));
   Instr Syscall]

let print_int_code = syscall Sys_print_int

let print_newline_code =
  Instr (La (A0, L "NL")) ::
  syscall Sys_print_string

(* ==== codegen ==== *)

let save rsrc offset = [Instr (Sw (rsrc,  IR (offset, Sp)))]
let restore rdest offset = [Instr (Lw (rdest, IR (offset, Sp)))]

let asm_operand r = function
    V.Param 1 ->
      if r = A0 then [] else [Instr (Move (r, A0))]
  | V.Param i ->
      err ("Implementation error in parameter access: " ^ string_of_int i)
  | V.Local n -> restore r n
  | V.Labimm l -> [Instr (La (r, L l))]
  | V.Imm n -> [Instr (Li (r, n))]

let prologue n = [Instr (Addiu (Sp, Sp, - (n + 8)))] @ save Ra (n + 4)
let epilogue n = restore Ra (n + 4) @ [Instr (Addiu (Sp, Sp, n + 8))]

let asm_decl (V.FunDecl(fname, instrs, n)) =
  let asm_instr = function
      V.Move (ofs, v) ->
        asm_operand T0 v @
        save T0 ofs
    | V.BinOp (ofs, op, v1, v2) ->
        asm_operand T0 v1 @
        asm_operand T1 v2 @
        [Instr (match op with
               S.Plus -> Add (T0, T0, T1)
             | S.Mult -> Mul (T0, T0, T1)
             | S.Lt   -> Slt (T0, T0, T1))] @
        save T0 ofs
    | V.Label l ->
        [Label l]
    | V.BranchIf (v, l) ->
        asm_operand T0 v @
        [Instr (Bgtz (T0, l))]
    | V.Goto l ->
        [Instr (J l)]
    | V.Call (ofs, f, [v]) ->
        save A0 n @
        asm_operand A0 v @
        asm_operand T0 f @
        [Instr (Jalr (Ra, T0))] @
        save V0 ofs @
        restore A0 n
    | V.Call _ -> err "Implementation error."
    | V.Return v ->
        asm_operand V0 v @
        [Instr (J (fname ^ "_ret"))]
  in
  [Label fname] @ prologue n @
  List.concat (List.map asm_instr instrs) @
  [Label (fname ^ "_ret")] @ epilogue n @ [Instr (Jr Ra)]

let asm ds =
  [Dir D_data;
   Label "NL";
   Dir (D_asciiz "\\n");
   Dir D_text;
   Dir (D_globl "main")] @
  List.concat (List.map asm_decl ds) @
  [Label "main"] @
  prologue 24 @  (* 適当 *)
  [Instr (Jal "_toplevel");
   Instr (Move (A0, V0))] @
  print_int_code @ print_newline_code @
  epilogue 24 @  (* 適当 *)
  [Instr (Jr Ra)]
