(*
type nat = int

let zero = 0
let iszero n = (n = 0)
let succ n = (n + 1)
let prev n =
    if n <= 0 then
        failwith "Not a natural number."
    else
        n - 1
let repr n = n
 *)

type nat =
    | Zero
    | Succ of nat

let zero = Zero
let iszero n = n = Zero
let succ n =
  match n with
  | Zero -> Succ Zero
  | _ -> Succ n
let prev n =
    match n with
    | Zero -> failwith "Not a natural number."
    | Succ n' -> n'
let rec repr n =
  match n with 
  | Zero -> 0
  | Succ n' -> repr n' + 1
