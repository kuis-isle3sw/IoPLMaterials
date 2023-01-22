open Miniml

let program = Syntax.show_program |> Fmt.of_to_string |> Alcotest.of_pp
let program_of_string str = Parser.toplevel Lexer.main (Lexing.from_string str)

let () =
  let open Alcotest in
  run "Lexer"
    [
      ( "main",
        let check = check program "" in
        [
          test_case "All comments are ignored (c.f. Exercise 3.2.4)" `Quick
            (fun () ->
              check (Syntax.Exp (ILit 1)) @@ program_of_string "1(**);;";
              check (Syntax.Exp (ILit 1))
              @@ program_of_string "1(*(* This is a comment. *)(**)*);;");
        ] );
    ]
