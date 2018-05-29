(* ==== 即値，ラベル ==== *)
type imm = int
type label = string

(* type cc = int <-- TODO: condition code? *)

(* ==== レジスタ ==== *)
let nreg = 4 (* 使用する汎用レジスタの個数 *)

type reg =
    Zero (* constant 0 *)
  | At   (* reserved for assembler *)
  | V0   (* expression evaluation and results of a function *)
  | V1   (* expression evaluation and results of a function *)

  | A0   (* argument 1 *)
  | A1   (* argument 2 *)
  | A2   (* argument 3 *)
  | A3   (* argument 4 *)

  | T0   (* temporary (not preserved accross call) *)
  | T1   (* temporary (not preserved accross call) *)
  | T2   (* temporary (not preserved accross call) *)
  | T3   (* temporary (not preserved accross call) *)
  | T4   (* temporary (not preserved accross call) *)
  | T5   (* temporary (not preserved accross call) *)
  | T6   (* temporary (not preserved accross call) *)
  | T7   (* temporary (not preserved accross call) *)
  | T8   (* temporary (not preserved accross call) *)
  | T9   (* temporary (not preserved accross call) *)

  | S0   (* saved temporary (preserved accross call) *)
  | S1   (* saved temporary (preserved accross call) *)
  | S2   (* saved temporary (preserved accross call) *)
  | S3   (* saved temporary (preserved accross call) *)
  | S4   (* saved temporary (preserved accross call) *)
  | S5   (* saved temporary (preserved accross call) *)
  | S6   (* saved temporary (preserved accross call) *)
  | S7   (* saved temporary (preserved accross call) *)

  | K0   (* reserved for OS kernel *)
  | K1   (* reserved for OS kernel *)

  | Gp   (* pointer to global area *)
  | Sp   (* stack pointer *)
  | Fp   (* frame pointer *)
  | Ra   (* return address (used by function call) *)

(* ==== アドレッシング・モード ==== *)
type addr =
    I  of imm         (* 即値 *)
  | R  of reg         (* レジスタ *)
  | IR of imm * reg   (* レジスタ間接 *)
  | L  of label       (* ラベル間接 *)

(* ==== 命令 ==== *)
type instr =
    Abs    of reg * reg          (* abs rdest, rsrc *)

  | Add    of reg * reg * reg    (* add   rd, rs, rt *)
  | Addi   of reg * reg * int    (* addi  rt, rs, imm *)
  | Addiu  of reg * reg * int    (* addiu rt, rs, imm *)
  | Addu   of reg * reg * reg    (* addu  rd, rs, rt *)

  | And    of reg * reg * reg    (* and  rd, rs, rt *)
  | Andi   of reg * reg * int    (* andi rt, rs, imm *)

  | B      of label              (* b      label *)
  (* | Bclf   of cc * label      (* bclf   cc label *) *)
  (* | Bclt   of cc * label      (* bclt   cc label *) *)
  | Beq    of reg * reg * label  (* beq    rs, rt, label *)
  | Beqz   of reg * label        (* beqz   rsrc, label *)
  | Bge    of reg * reg * label  (* bge    rsrc1, rsrc2, label *)
  | Bgeu   of reg * reg * label  (* bgeu   rsrc1, rsrc2, label *)
  | Bgez   of reg * label        (* bgez   rs, label *)
  | Bgezal of reg * label        (* bgezal rs, label *)
  | Bgt    of reg * reg * label  (* bgt    rsrc1, src2, label *)
  | Bgtu   of reg * reg * label  (* bgtu   rsrc1, src2, label *)
  | Bgtz   of reg * label        (* bgtz   rs, label *)
  | Ble    of reg * reg * label  (* ble    rsrc1, src2, label *)
  | Bleu   of reg * reg * label  (* bleu   rsrc1, src2, label *)
  | Blez   of reg * label        (* blez   rs, label *)
  | Blt    of reg * reg * label  (* blt    rsrc1, rsrc2, label *)
  | Bltu   of reg * reg * label  (* bltu   rsrc1, rsrc2, label *)
  | Bltz   of reg * label        (* bltz   rs, label *)
  | Bltzal of reg * label        (* bltzal rs, label *)
  | Bne    of reg * reg * label  (* bne    rs, rt, label *)
  | Bnez   of reg * label        (* bnez   rsrc, label *)

  | Clo    of reg * reg          (* clo rd, rs *)
  | Clz    of reg * reg          (* clz rd, rs *)

  | Div  of reg * reg * reg option (* div  rs, rt / div  rdest, rsrc1, src2 *)
  | Divu of reg * reg * reg option (* divu rs, rt / divu rdest, rsrc1, src2 *)

  | J    of label        (* j    target *)
  | Jal  of label        (* jal  target *)
  | Jalr of reg * reg    (* jalr rs, rd *)
  | Jr   of reg          (* jr   rs *)

  | Li   of reg * imm    (* li  rdest, imm *)
  | Lui  of reg * imm    (* lui rt, imm *)

  | La   of reg * addr   (* la   rdest, address *)
  | Lb   of reg * addr   (* lb   rt, address *)
  | Lbu  of reg * addr   (* lbu  rt, address *)
  | Ld   of reg * addr   (* ld   rdest, address *)
  | Lh   of reg * addr   (* lh   rt, address *)
  | Lhu  of reg * addr   (* lhu  rt, address *)
  | Ll   of reg * addr   (* ll   rt, address *)
  | Lw   of reg * addr   (* lw   rt, address *)
  | Lwc1 of reg * addr   (* lwc1 ft, address *)
  | Lwl  of reg * addr   (* lwl  rt, address *)
  | Lwr  of reg * addr   (* lwr  rt, address *)
  | Ulh  of reg * addr   (* ulh  rdest, address *)
  | Ulhu of reg * addr   (* ulhu rdest, address *)
  | Ulw  of reg * addr   (* ulw  rdest, address *)

  | Move of reg * reg         (* move rdest rsrc *)
  (* | Movf of reg * reg * cc (* movf rd, rs, cc *) *)
  | Movn of reg * reg * reg   (* movn rd, rs, rt *)
  (* | Movt of reg * reg * cc (* movt rd, rs, cc *) *)
  | Movz of reg * reg * reg   (* movz rd, rs, rt *)
  | Mfc0 of reg * reg         (* mfc0 rt, rd *)
  | Mfc1 of reg * reg         (* mfc1 rt, fs *)
  | Mfhi of reg               (* mfhi rd *)
  | Mflo of reg               (* mflo rd *)
  | Mthi of reg               (* mthi rs *)
  | Mtlo of reg               (* mtlo rs *)
  | Mtc0 of reg * reg         (* mtc0 rd, rt *)
  | Mtc1 of reg * reg         (* mtc1 rd, fs *)

  | Madd  of reg * reg        (* madd  rs, rt *)
  | Maddu of reg * reg        (* maddu rs, rt *)

  | Mul   of reg * reg * reg  (* mul   rd, rs, rt *)
  | Mulo  of reg * reg * reg  (* mulo  rdest, rsrc1, src2 *)
  | Mulou of reg * reg * reg  (* mulou rdest, rsrc1, src2 *)

  | Mult  of reg * reg        (* mult  rs, rt *)
  | Multu of reg * reg        (* multu rs, rt *)

  | Neg   of reg * reg        (* neg  rdest, rsrc *)
  | Negu  of reg * reg        (* negu rdest, rsrc *)

  | Nop                       (* nop *)

  | Nor   of reg * reg * reg  (* nor rd, rs, rt *)

  | Not   of reg * reg        (* not rdest, rsrc *)

  | Or    of reg * reg * reg  (* or  rd, rs, rt *)
  | Ori   of reg * reg * imm  (* ori rt, rs, imm *)

  | Rem   of reg * reg * reg  (* rem rdest, rsrc1, rsrc2 *)
  | Remu  of reg * reg * reg  (* rem rdest, rsrc1, rsrc2 *)

  | Rol   of reg * reg * reg  (* rol rdest, rsrc1, rsrc2 *)
  | Ror   of reg * reg * reg  (* ror rdest, rsrc1, rsrc2 *)

  | Sb    of reg * addr       (* sb   rt, address *)
  | Sc    of reg * addr       (* sc   rt, address *)
  | Sd    of reg * addr       (* sd   rsrc, address *)
  | Sh    of reg * addr       (* sh   rt, address *)
  | Sw    of reg * addr       (* sw   rt, address *)
  | Swc1  of reg * addr       (* swc1 ft, address *)
  | Sdc1  of reg * addr       (* sdc1 ft, address *)
  | Swl   of reg * addr       (* swl  rt, address *)
  | Swr   of reg * addr       (* swr  rt, address *)
  | Ush   of reg * addr       (* ush  rsrc, address *)
  | Usw   of reg * addr       (* usw  rsrc, address *)

  | Seq   of reg * reg * reg  (* seq   rdest, rsrc1, rsrc2 *)
  | Sge   of reg * reg * reg  (* sge   rdest, rsrc1, rsrc2 *)
  | Sgeu  of reg * reg * reg  (* sgeu  rdest, rsrc1, rsrc2 *)
  | Sgt   of reg * reg * reg  (* sgt   rdest, rsrc1, rsrc2 *)
  | Sgtu  of reg * reg * reg  (* sgtu  rdest, rsrc1, rsrc2 *)
  | Sle   of reg * reg * reg  (* sle   rdest, rsrc1, rsrc2 *)
  | Sleu  of reg * reg * reg  (* sleu  rdest, rsrc1, rsrc2 *)
  | Slt   of reg * reg * reg  (* slt   rd, rs, rt *)
  | Slti  of reg * reg * imm  (* sltu  rt, rs, imm *)
  | Sltiu of reg * reg * imm  (* sltiu rt, rs, imm *)
  | Sltu  of reg * reg * reg  (* sltu  rd, rs, rt *)
  | Sne   of reg * reg * reg  (* sne   rdest, rsrc1, rsrc2 *)

  | Sll   of reg * reg * int  (* sll  rd, rt, shamt *)
  | Sllv  of reg * reg * reg  (* sllv rd, rt, rs *)
  | Sra   of reg * reg * int  (* sra  rd, rt, shamt *)
  | Srav  of reg * reg * reg  (* srav rd, rt, rs *)
  | Srl   of reg * reg * int  (* srl  rd, rt, shamt *)
  | Srlv  of reg * reg * reg  (* srlv rd, rt, rs *)

  | Sub   of reg * reg * reg  (* sub  rd, rs, rt *)
  | Subu  of reg * reg * reg  (* subu rd, rs, rt *)

  | Syscall                   (* syscall *)

  | Xor   of reg * reg * reg  (* xor  rd, rs, rt *)
  | Xori  of reg * reg * imm  (* xori rt, rs, imm *)


(* ==== アセンブラ指示子 ==== *)
type directive =
    D_align  of int
  | D_ascii  of string
  | D_asciiz of string
  | D_byte   of int list
  | D_data
  | D_double of float list
  | D_extern of string * int
  | D_float  of float list
  | D_globl  of string
  | D_half   of int list
  | D_kdata
  | D_ktext
  | D_set_no_at
  | D_set_at
  | D_space  of int
  | D_text
  | D_word   of int list

(* a line of code *)
type loc = 
    Dir of directive
  | Label of label
  | Instr of instr


(* ==== システム・コール ==== *)
type syscall =
    Sys_print_int
  | Sys_print_float
  | Sys_print_double
  | Sys_print_string
  | Sys_read_int
  | Sys_read_float
  | Sys_read_double
  | Sys_read_string
  | Sys_sbrk
  | Sys_exit
  | Sys_print_char
  | Sys_read_char
  | Sys_open
  | Sys_read
  | Sys_write
  | Sys_close
  | Sys_exit2

let syscall_to_num = function
    Sys_print_int    -> 1
  | Sys_print_float  -> 2
  | Sys_print_double -> 3
  | Sys_print_string -> 4
  | Sys_read_int     -> 5
  | Sys_read_float   -> 6
  | Sys_read_double  -> 7
  | Sys_read_string  -> 8
  | Sys_sbrk         -> 9
  | Sys_exit         -> 10
  | Sys_print_char   -> 11
  | Sys_read_char    -> 12
  | Sys_open         -> 13
  | Sys_read         -> 14
  | Sys_write        -> 15
  | Sys_close        -> 16
  | Sys_exit2        -> 17


(* ==== 仮想マシンコードの文字列化関数 ==== *)

let string_of_reg r = "$" ^ match r with
    Zero -> "zero"
  | At   -> "at"
  | V0   -> "v0"
  | V1   -> "v1"
  | A0   -> "a0"
  | A1   -> "a1"
  | A2   -> "a2"
  | A3   -> "a3"
  | T0   -> "t0"
  | T1   -> "t1"
  | T2   -> "t2"
  | T3   -> "t3"
  | T4   -> "t4"
  | T5   -> "t5"
  | T6   -> "t6"
  | T7   -> "t7"
  | T8   -> "t8"
  | T9   -> "t9"
  | S0   -> "s0"
  | S1   -> "s1"
  | S2   -> "s2"
  | S3   -> "s3"
  | S4   -> "s4"
  | S5   -> "s5"
  | S6   -> "s6"
  | S7   -> "s7"
  | K0   -> "k0"
  | K1   -> "k1"
  | Gp   -> "gp"
  | Sp   -> "sp"
  | Fp   -> "fp"
  | Ra   -> "ra"

let string_of_addr = function
    I i -> string_of_int i
  | R r -> string_of_reg r
  | IR (i, r) -> Printf.sprintf "%d(%s)" i (string_of_reg r)
  | L l -> l

let string_of_instr instr =
  let emit_instr op rands = op ^ "\t" ^ (String.concat ", " rands)
  in match instr with
    Abs (r1, r2) ->
      emit_instr "abs" [string_of_reg r1; string_of_reg r2]
  | Add (r1, r2, r3) ->
      emit_instr "add" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Addi (r1, r2, i) ->
      emit_instr "addi" [string_of_reg r1; string_of_reg r2;
                         string_of_int i]
  | Addiu (r1, r2, i) ->
      emit_instr "addiu" [string_of_reg r1; string_of_reg r2;
                          string_of_int i]
  | Addu (r1, r2, r3) ->
      emit_instr "addu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | And (r1, r2, r3) ->
      emit_instr "and" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Andi (r1, r2, i) ->
      emit_instr "andi" [string_of_reg r1; string_of_reg r2;
                         string_of_int i]
  | B lbl ->
      emit_instr "b" [lbl]
  | Beq (r1, r2, lbl) ->
      emit_instr "beq" [string_of_reg r1; string_of_reg r2; lbl]
  | Beqz (r, lbl) ->
      emit_instr "beqz" [string_of_reg r; lbl]
  | Bge (r1, r2, lbl) ->
      emit_instr "bge" [string_of_reg r1; string_of_reg r2; lbl]
  | Bgeu (r1, r2, lbl) ->
      emit_instr "bgeu" [string_of_reg r1; string_of_reg r2; lbl]
  | Bgez (r, lbl) ->
      emit_instr "bgez" [string_of_reg r; lbl]
  | Bgezal (r, lbl) ->
      emit_instr "bgezal" [string_of_reg r; lbl]
  | Bgt (r1, r2, lbl) ->
      emit_instr "bgt" [string_of_reg r1; string_of_reg r2; lbl]
  | Bgtu (r1, r2, lbl) ->
      emit_instr "bgtu" [string_of_reg r1; string_of_reg r2; lbl]
  | Bgtz (r, lbl) ->
      emit_instr "bgtz" [string_of_reg r; lbl]
  | Ble (r1, r2, lbl) ->
      emit_instr "ble" [string_of_reg r1; string_of_reg r2; lbl]
  | Bleu (r1, r2, lbl) ->
      emit_instr "bleu" [string_of_reg r1; string_of_reg r2; lbl]
  | Blez (r, lbl) ->
      emit_instr "blez" [string_of_reg r; lbl]
  | Blt (r1, r2, lbl) ->
      emit_instr "blt" [string_of_reg r1; string_of_reg r2; lbl]
  | Bltu (r1, r2, lbl) ->
      emit_instr "bltu" [string_of_reg r1; string_of_reg r2; lbl]
  | Bltz (r, lbl) ->
      emit_instr "bltz" [string_of_reg r; lbl]
  | Bltzal (r, lbl) ->
      emit_instr "bltzal" [string_of_reg r; lbl]
  | Bne (r1, r2, lbl) ->
      emit_instr "bne" [string_of_reg r1; string_of_reg r2; lbl]
  | Bnez (r, lbl) ->
      emit_instr "bnez" [string_of_reg r; lbl]
  | Clo (r1, r2) ->
      emit_instr "clo" [string_of_reg r1; string_of_reg r2]
  | Clz (r1, r2) ->
      emit_instr "clz" [string_of_reg r1; string_of_reg r2]
  | Div (r1, r2, None) ->
      emit_instr "div" [string_of_reg r1; string_of_reg r2]
  | Div (r1, r2, Some r3) ->
      emit_instr "div" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Divu (r1, r2, None) ->
      emit_instr "divu" [string_of_reg r1; string_of_reg r2]
  | Divu (r1, r2, Some r3) ->
      emit_instr "divu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | J lbl ->
      emit_instr "j" [lbl]
  | Jal lbl ->
      emit_instr "jal" [lbl]
  | Jalr (r1, r2) ->
      emit_instr "jalr" [string_of_reg r1; string_of_reg r2]
  | Jr r ->
      emit_instr "jr" [string_of_reg r]
  | Li (r, i) ->
      emit_instr "li" [string_of_reg r; string_of_int i]
  | Lui (r, i) ->
      emit_instr "lui" [string_of_reg r; string_of_int i]
  | La (r, a) ->
      emit_instr "la" [string_of_reg r; string_of_addr a]
  | Lb (r, a) ->
      emit_instr "lb" [string_of_reg r; string_of_addr a]
  | Lbu (r, a) ->
      emit_instr "lbu" [string_of_reg r; string_of_addr a]
  | Ld (r, a) ->
      emit_instr "ld" [string_of_reg r; string_of_addr a]
  | Lh (r, a) ->
      emit_instr "lh" [string_of_reg r; string_of_addr a]
  | Lhu (r, a) ->
      emit_instr "lhu" [string_of_reg r; string_of_addr a]
  | Ll (r, a) ->
      emit_instr "ll" [string_of_reg r; string_of_addr a]
  | Lw (r, a) ->
      emit_instr "lw" [string_of_reg r; string_of_addr a]
  | Lwc1 (r, a) ->
      emit_instr "lwc1" [string_of_reg r; string_of_addr a]
  | Lwl (r, a) ->
      emit_instr "lwl" [string_of_reg r; string_of_addr a]
  | Lwr (r, a) ->
      emit_instr "lwr" [string_of_reg r; string_of_addr a]
  | Ulh (r, a) ->
      emit_instr "ulh" [string_of_reg r; string_of_addr a]
  | Ulhu (r, a) ->
      emit_instr "ulhu" [string_of_reg r; string_of_addr a]
  | Ulw (r, a) ->
      emit_instr "ulw" [string_of_reg r; string_of_addr a]
  | Move (r1, r2) ->
      emit_instr "move" [string_of_reg r1; string_of_reg r2]
  | Movn (r1, r2, r3) ->
      emit_instr "movn" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Movz (r1, r2, r3) ->
      emit_instr "movz" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Mfc0 (r1, r2) ->
      emit_instr "mfc0" [string_of_reg r1; string_of_reg r2]
  | Mfc1 (r1, r2) ->
      emit_instr "mfc1" [string_of_reg r1; string_of_reg r2]
  | Mfhi r ->
      emit_instr "mfhi" [string_of_reg r]
  | Mflo r ->
      emit_instr "mflo" [string_of_reg r]
  | Mthi r ->
      emit_instr "mthi" [string_of_reg r]
  | Mtlo r ->
      emit_instr "mtlo" [string_of_reg r]
  | Mtc0 (r1, r2) ->
      emit_instr "mtc0" [string_of_reg r1; string_of_reg r2]
  | Mtc1 (r1, r2) ->
      emit_instr "mtc1" [string_of_reg r1; string_of_reg r2]
  | Madd (r1, r2) ->
      emit_instr "madd" [string_of_reg r1; string_of_reg r2]
  | Maddu (r1, r2) ->
      emit_instr "maddu" [string_of_reg r1; string_of_reg r2]
  | Mul (r1, r2, r3) ->
      emit_instr "mul" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Mulo (r1, r2, r3) ->
      emit_instr "mulo" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Mulou (r1, r2, r3) ->
      emit_instr "mulou" [string_of_reg r1; string_of_reg r2;
                          string_of_reg r3]
  | Mult (r1, r2) ->
      emit_instr "mult" [string_of_reg r1; string_of_reg r2]
  | Multu (r1, r2) ->
      emit_instr "multu" [string_of_reg r1; string_of_reg r2]
  | Neg (r1, r2) ->
      emit_instr "neg" [string_of_reg r1; string_of_reg r2]
  | Negu (r1, r2) ->
      emit_instr "negu" [string_of_reg r1; string_of_reg r2]
  | Nop -> emit_instr "nop" []
  | Nor (r1, r2, r3) ->
      emit_instr "nor" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Not (r1, r2) ->
      emit_instr "not" [string_of_reg r1; string_of_reg r2]
  | Or (r1, r2, r3) ->
      emit_instr "or" [string_of_reg r1; string_of_reg r2;
                       string_of_reg r3]
  | Ori (r1, r2, i) ->
      emit_instr "ori" [string_of_reg r1; string_of_reg r2;
                        string_of_int i]
  | Rem (r1, r2, r3) ->
      emit_instr "rem" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Remu (r1, r2, r3) ->
      emit_instr "remu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Rol (r1, r2, r3) ->
      emit_instr "rol" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Ror (r1, r2, r3) ->
      emit_instr "ror" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Sb (r, a) ->
      emit_instr "sb" [string_of_reg r; string_of_addr a]
  | Sc (r, a) ->
      emit_instr "sc" [string_of_reg r; string_of_addr a]
  | Sd (r, a) ->
      emit_instr "sd" [string_of_reg r; string_of_addr a]
  | Sh (r, a) ->
      emit_instr "sh" [string_of_reg r; string_of_addr a]
  | Sw (r, a) ->
      emit_instr "sw" [string_of_reg r; string_of_addr a]
  | Swc1 (r, a) ->
      emit_instr "swc1" [string_of_reg r; string_of_addr a]
  | Sdc1 (r, a) ->
      emit_instr "sdc1" [string_of_reg r; string_of_addr a]
  | Swl (r, a) ->
      emit_instr "swl" [string_of_reg r; string_of_addr a]
  | Swr (r, a) ->
      emit_instr "swr" [string_of_reg r; string_of_addr a]
  | Ush (r, a) ->
      emit_instr "ush" [string_of_reg r; string_of_addr a]
  | Usw (r, a) ->
      emit_instr "usw" [string_of_reg r; string_of_addr a]
  | Seq (r1, r2, r3) ->
      emit_instr "seq" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Sge (r1, r2, r3) ->
      emit_instr "sge" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Sgeu (r1, r2, r3) ->
      emit_instr "sgeu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Sgt (r1, r2, r3) ->
      emit_instr "sgt" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Sgtu (r1, r2, r3) ->
      emit_instr "sgtu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Sle (r1, r2, r3) ->
      emit_instr "sle" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Sleu (r1, r2, r3) ->
      emit_instr "sleu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Slt (r1, r2, r3) ->
      emit_instr "slt" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Slti (r1, r2, i) ->
      emit_instr "slti" [string_of_reg r1; string_of_reg r2;
                         string_of_int i]
  | Sltiu (r1, r2, i) ->
      emit_instr "sltiu" [string_of_reg r1; string_of_reg r2;
                          string_of_int i]
  | Sltu (r1, r2, r3) ->
      emit_instr "sltu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Sne (r1, r2, r3) ->
      emit_instr "sne" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Sll (r1, r2, i) ->
      emit_instr "sll" [string_of_reg r1; string_of_reg r2;
                        string_of_int i]
  | Sllv (r1, r2, r3) ->
      emit_instr "sllv" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Sra (r1, r2, i) ->
      emit_instr "sra" [string_of_reg r1; string_of_reg r2;
                        string_of_int i]
  | Srav (r1, r2, r3) ->
      emit_instr "srav" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Srl (r1, r2, i) ->
      emit_instr "srl" [string_of_reg r1; string_of_reg r2;
                        string_of_int i]
  | Srlv (r1, r2, r3) ->
      emit_instr "srlv" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Sub (r1, r2, r3) ->
      emit_instr "sub" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Subu (r1, r2, r3) ->
      emit_instr "subu" [string_of_reg r1; string_of_reg r2;
                         string_of_reg r3]
  | Syscall ->
      emit_instr "syscall" []
  | Xor (r1, r2, r3) ->
      emit_instr "xor" [string_of_reg r1; string_of_reg r2;
                        string_of_reg r3]
  | Xori (r1, r2, i) ->
      emit_instr "xori" [string_of_reg r1; string_of_reg r2;
                         string_of_int i]

let string_of_directive = function
    D_align      i -> "align " ^ string_of_int i
  | D_ascii      s -> "ascii \"" ^ s ^ "\""
  | D_asciiz     s -> "asciiz \"" ^ s ^ "\""
  | D_byte      is -> "byte " ^ String.concat ", " (List.map string_of_int is)
  | D_data         -> "data"
  | D_double fs -> "double " ^ String.concat ", " (List.map string_of_float fs)
  | D_extern (s,i) -> "extern " ^ s ^ ", " ^ string_of_int i
  | D_float  fs ->  "float " ^ String.concat ", " (List.map string_of_float fs)
  | D_globl      s -> "globl " ^ s
  | D_half      is -> "half " ^ String.concat ", " (List.map string_of_int is)
  | D_kdata        -> "kdata"
  | D_ktext        -> "ktext"
  | D_set_no_at    -> "set noat"
  | D_set_at       -> "set at"
  | D_space      i -> "space " ^ string_of_int i
  | D_text         -> "text"
  | D_word      is -> "word " ^ String.concat ", " (List.map string_of_int is)

let string_of_loc = function
    Instr i -> "\t" ^ string_of_instr i
  | Label l -> l ^ ":"
  | Dir   d -> "\t." ^ string_of_directive d

(* entry point *)
let string_of prog = String.concat "\n" (List.map string_of_loc prog)
