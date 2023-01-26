(* Exercise 3.4.4 *)
(* 12 *)
let makemult maker x = if x < 1 then 0 else 4 + maker maker (x + -1) in
let times4 x = makemult makemult x in
times4 3
;;

(* 24 *)
let makefact maker x = if x < 1 then 1 else x * maker maker (x + -1) in
let fact x = makefact makefact x in
fact 4
;;
