(* This is a comment. *)
1 + 1;;

let x = 2
let y = x * 3;;

(* 9 *)
let z = 1 in
x + y + z;;

(* 102 *)
let x = 100
and y = x in x+y;;

(* 20 *)
let threetimes = fun f -> fun x -> f (f x x) (f x x) in
  threetimes (+) 5;;