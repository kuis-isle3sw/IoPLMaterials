let debug = ref false

let dprint s =
  if !debug
  then (
    print_string (s ());
    flush stdout)
;;

let display_cfg = ref false
let optimize = ref false
let outfile = ref "-"

let compile prompt ichan cont =
  print_string prompt;
  flush stdout;
  (* このmain.ml自体の説明(コンパイラの全体構成) (1章後半) *)

  (* Parsing (2章) *)
  let prog = Parser.toplevel Lexer.main (Lexing.from_channel ichan) in
  (* Normal form conversion (3章) *)
  let norm = Normal.convert prog in
  dprint (fun () -> "(* [Normal form] *)\n" ^ Normal.string_of_norm norm);
  (* Closure conversion (4章) *)
  let closed = Closure.convert norm in
  dprint (fun () -> "\n(* [Closure] *)\n" ^ Closure.string_of_closure closed);
  (* Flattening (5章前半) *)
  let flat = Flat.flatten closed in
  dprint (fun () -> "\n(* [Flat] *)\n" ^ Flat.string_of_flat flat);
  (* Translate to VM (5章後半) *)
  let vmcode = Vm.trans flat in
  dprint (fun () -> "\n(* [VM code] *)\n" ^ Vm.string_of_vm vmcode);
  (* 制御フローグラフを表示 *)
  if !display_cfg && not !optimize then Cfg.display_cfg (Cfg.build vmcode) None;
  let armcode =
    if !optimize
    then (
      (* Low-level opt. (7章 DFA & 最適化) *)
      let regcode = Opt.optimize !display_cfg Arm_spec.nreg vmcode in
      dprint (fun () -> "(* [Reg code] *)\n" ^ Reg.string_of_reg regcode ^ "\n");
      (* Convert to ARM assembly (7章 コード生成(レジスタ利用版)) *)
      Arm_reg.codegen regcode)
    else (* Convert to ARM assembly (6章 コード生成) *)
      Arm_noreg.codegen vmcode
  in
  (* Output to stdout/file *)
  let ochan = if !outfile = "-" then stdout else open_out !outfile in
  let () = output_string ochan (Arm_spec.string_of armcode ^ "\n") in
  if !outfile <> "-" then close_out ochan;
  (* continued... *)
  cont ()
;;

(* ==== main ==== *)

let srcfile = ref "-"
let usage = "Usage: " ^ Sys.argv.(0) ^ " [-vOG] [-o ofile] [file]"

let aspec =
  Arg.align
    [ "-o", Arg.Set_string outfile, " Set output file (default: stdout)"
    ; ( "-O"
      , Arg.Unit (fun () -> optimize := true)
      , " Perform optimization (default: " ^ string_of_bool !optimize ^ ")" )
    ; ( "-G"
      , Arg.Unit (fun () -> display_cfg := true)
      , " Display CFG (default: " ^ string_of_bool !display_cfg ^ ")" )
    ; ( "-v"
      , Arg.Unit (fun () -> debug := true)
      , " Print debug info (default: " ^ string_of_bool !debug ^ ")" )
    ]
;;

let main () =
  Arg.parse aspec (fun s -> srcfile := s) usage;
  if !srcfile = "-"
  then (
    let c = stdin in
    let rec k () = compile "# " c k in
    compile "# " c k)
  else (
    let c = open_in !srcfile in
    let k () = close_in c in
    compile "" c k)
;;

let () = main ()
