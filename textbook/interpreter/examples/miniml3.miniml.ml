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

(* Exercise 3.4.6 *)
(* 25 *)
let fact = fun n -> n + 1 in
let fact = fun n -> if n < 1 then 1 else n * fact (n + -1) in
fact 5
;;

(* 25 *)
let fact = dfun n -> n + 1 in
let fact = fun n -> if n < 1 then 1 else n * fact (n + -1) in
fact 5
;;

(* 120 *)
let fact = fun n -> n + 1 in
let fact = dfun n -> if n < 1 then 1 else n * fact (n + -1) in
fact 5
;;

(* 120 *)
let fact = dfun n -> n + 1 in
let fact = dfun n -> if n < 1 then 1 else n * fact (n + -1) in
fact 5
;;
