let debug = ref true
let dprint s = if !debug then (print_string (s ()) ; flush stdout)

let outfile = ref "-"

let initial_decls = []

let rec compile prompt ichan cont =
  print_string prompt; flush stdout;

  let ast = Parser.toplevel Lexer.main (Lexing.from_channel ichan) in
  dprint (fun () ->
      "\n(* [AST] *)\n" ^ (Syntax.string_of_pgm ast) ^ ";;\n");

  let ccode = C.i_of_pgm ast in
  dprint (fun () ->
      "\n(* [C] *)\n" ^ (C.string_of_pgm ccode) ^ ";;\n");

  let vmcode = V.vt ccode in
  dprint (fun () -> "\n(* [VM] *)\n" ^ (V.string_of_pgm vmcode) ^ "\n\n");

  let mipscode = Mips_gen.asm vmcode in
  (* Output to stdout/file *)
  let ochan = if !outfile = "-" then stdout else open_out !outfile in
  let () = output_string ochan
      (Mips_spec.string_of mipscode ^ "\n") in
  if !outfile <> "-" then close_out ochan;

  (* continued... *)
  cont ()


(* ==== main ==== *)

let srcfile = ref "-"

let usage = "Usage: " ^ Sys.argv.(0) ^ " [-v] [-o ofile] [file]"

let aspec = Arg.align [
    ("-o", Arg.Set_string outfile,
     " Set output file (default: stdout)");
    ("-v", Arg.Unit (fun () -> debug := true),
     " Print debug info (default: " ^ (string_of_bool !debug) ^ ")");
  ]

let main () =
  Arg.parse aspec (fun s -> srcfile := s) usage;
  if !srcfile = "-" then
    let c = stdin in
    let rec k () = compile "# " c k in
    compile "# " c k
  else
    let c = open_in !srcfile in
    let rec k () = close_in c in
    compile "" c k

let _ = main ()
