
(* Exercise 1.0.1 *)
(* 
let rec f x = if x = 0 then x else false;; 
*) 

(* 浮動小数で表現された円の半径 r をとり，その面積を求める関数
   circle_area を書け *)
let pi = 3.141592653589793238462643383279;;
let circle_area r =
  pi *. r *. r
;;

(* 階乗 *)
let rec fact n =
  if n = 0 then
    1
  else
    n * (fact (n - 1))
;;

(* 階乗（末尾再帰 tail recursion）*)
let rec fact_iter_sub n res =
  if n = 0 then
    res
  else
    fact_iter_sub (n - 1) (n * res)
;;
let fact_iter n = fact_iter_sub n 1
;;

(* 整数のリスト l を受け取り，その要素の和を求める関数 sum を書け *)
let rec sum l =
  match l with
  | [] -> 0
  | hd::tl ->
    (* hd : int, tl : int list *)
    hd + (sum tl)
;;

(* 整数のリスト l と整数から整数への関数 f を受け取り，f を l の要素そ
   れぞれに適用して得られるリストを返す関数 map を書け *)
let rec map f l =
  match l with
  | [] -> []
  | hd::tl -> (f hd)::(map f tl)
;;

(* 教科書の Exercise 1.0.2 *)
type bt =
  | Leaf
  | Node of int * bt * bt
;;

let rec sumtree bt =
  match bt with
  | Leaf -> 0
  | Node(n, btleft, btright) ->
    n + (sumtree btleft) + (sumtree btright)
;;

let rec maptree f bt =
  match bt with
  | Leaf -> Leaf
  | Node(n, bt1, bt2) ->
    Node(f n, maptree f bt1, maptree f bt2)
;;
