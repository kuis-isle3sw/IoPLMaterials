
(* 浮動小数で表現された円の半径 r をとり，その面積を求める関数
   circle_area を書け *)

let pi = 3.141592653589793238462643383279
let circle_area r =
  pi *. r *. r
;;

(* 階乗 *)

(* 
   n=0 --> 1
   n=k+1 --> n * (fact k)
 *)

let rec fact n =
  if n = 0 then
    1
  else
    n * (fact (n - 1))
;;

let rec fact2 n =
  match n with
  | 0 -> 1
  | _ -> n * (fact (n - 1))
;;

(* 階乗（末尾再帰 tail recursion）*)

(* 整数のリスト l を受け取り，その要素の和を求める関数 sum を書け *)

(* 整数のリスト l と整数から整数への関数 f を受け取り，f を l の要素そ
   れぞれに適用して得られるリストを返す関数 map を書け *)

(* 教科書の Exercise 1.0.2 *)

