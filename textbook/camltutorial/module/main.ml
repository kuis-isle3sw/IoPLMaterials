let rec add n1 n2 =
  if Nat.iszero n1 then n2 else add (Nat.prev n1) (Nat.succ n2)

(* Tests *)
let () =
  (* 以下のスコープではプレフィクス Nat をつけなくてよいという宣言 *)
  let open Nat in
  assert (repr zero = 0);
  assert (repr (add zero zero) = 0);
  assert (repr (prev (succ zero)) = 0);
  assert (repr (add (succ (succ zero)) (succ zero)) = 3)
