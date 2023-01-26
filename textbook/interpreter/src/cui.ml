open Eval

let rec read_eval_print env =
  print_string "# ";
  flush stdout;
  try
    let program = Parser.toplevel Lexer.main (Lexing.from_channel stdin) in
    let _ =
      print_string "parsing done\n";
      flush stdout
    in
    let defs, newenv = eval_program env program in
    List.iter
      (fun (id, v) -> Printf.printf "val %s = %s\n" id (string_of_exval v))
      defs;
    read_eval_print newenv
  with exn ->
    Printf.printf "Fatal error: exception %s\n" (Printexc.to_string exn);
    read_eval_print env

let initial_env =
  List.fold_left
    (fun env (id, exval) -> Environment.extend id exval env)
    (snd @@ eval_program Environment.empty MyStdlib.program)
    [
      ("x", IntV 10);
      ("v", IntV 5);
      ("i", IntV 1);
      ("ii", IntV 2);
      ("iii", IntV 3);
      ("iv", IntV 4);
    ]
