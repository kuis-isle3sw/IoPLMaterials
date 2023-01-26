open Eval

let rec eval_print env lexbuf =
  (* NOTE:
     `Lexer.main` seems to execute `exit 0`
     when a certain string (an unacceptble string?; ex. "\n") is inputted. *)
  let program = Parser.toplevel Lexer.main lexbuf in
  let defs, newenv = eval_program env program in
  List.iter
    (fun (id, v) -> Printf.printf "val %s = %s\n" id (string_of_exval v))
    defs;
  eval_print newenv lexbuf

(* NOTE: No exception handling to perform the same behavior as the original *)
let read_eval_print filename =
  filename |> MyFile.read_whole |> Lexing.from_string
  |> eval_print (snd @@ eval_program Environment.empty MyStdlib.program)
