let _ =
  (* NOTE: Line breaks for when the text displayed before the command is executed does not break a line.*)
  print_newline ();

  let args =
    (* NOTE: `Sys.argv` must contain a command name at the first. *)
    match Array.to_list Sys.argv with
    | [] -> failwith "Shouldn't reach here"
    | _cmd :: args -> args
  in
  match args with
  | [] -> Miniml.Cui.read_eval_print Miniml.Cui.initial_env
  | filename :: _ -> Miniml.Batch.read_eval_print filename
