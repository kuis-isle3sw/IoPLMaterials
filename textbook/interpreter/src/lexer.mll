{
let reservedWords = [
  (* Keywords *)
  ("else", Parser.ELSE);
  ("false", Parser.FALSE);
  ("if", Parser.IF);
  ("then", Parser.THEN);
  ("true", Parser.TRUE);
  ("in", Parser.IN);
  ("let", Parser.LET);
  ("and", Parser.AND);
  ("fun", Parser.FUN);
  ("dfun", Parser.DFUN);
]
}

rule main = parse
  (* ignore spacing and newline characters *)
| [' ' '\009' '\012' '\n']+     { main lexbuf }
| "(*" { comment 0 lexbuf }

| "-"? ['0'-'9']+
    { Parser.INTV (int_of_string (Lexing.lexeme lexbuf)) }

| "(" { Parser.LPAREN }
| ")" { Parser.RPAREN }
| ";;" { Parser.SEMISEMI }
| "+" { Parser.PLUS }
| "*" { Parser.MULT }
| "<" { Parser.LT }
| "&&" { Parser.LAND }
| "||" { Parser.LOR }
| "=" { Parser.EQ }
| "->" { Parser.RARROW }

| ['a'-'z'] ['a'-'z' '0'-'9' '_' '\'']*
    { let id = Lexing.lexeme lexbuf in
      try
        List.assoc id reservedWords
      with
      _ -> Parser.ID id
     }
| eof { exit 0 }

and comment level = parse
| "(*" { comment (level+1) lexbuf }
| "*)" { if level = 0 then main lexbuf else comment (level-1) lexbuf }
| eof { exit 0 }
| _ { comment level lexbuf }
