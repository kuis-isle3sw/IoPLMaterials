(* 浮動小数で表現された円の半径 r をとり，その面積を求める関数
   circle_area を書け *)

let pi = 3.141592653589793238462643383279
let circle_area r = pi *. r *. r

(* 階乗 *)

(*
   n=0 --> 1
   n=k+1 --> n * (fact k)
*)

let rec fact n = if n = 0 then 1 else n * fact (n - 1)

(* パターンマッチを使った例 *)
let fact2 n = match n with 0 -> 1 | _ -> n * fact (n - 1)

(* 階乗（末尾再帰 tail recursion）*)

let rec fact_iter r n = if n = 0 then r else fact_iter (r * n) (n - 1)
let fact n = fact_iter 1 n

(* 整数のリスト l を受け取り，その要素の和を求める関数 sum を書け *)

let rec sum l = match l with [] -> 0 | hd :: tl -> hd + sum tl

(* 整数のリスト l と整数から整数への関数 f を受け取り，f を l の要素そ
   れぞれに適用して得られるリストを返す関数 map を書け *)

let rec map f l = match l with [] -> [] | hd :: tl -> f hd :: map f tl

(* 教科書の Exercise 1.0.2 *)

(* 二分木をあらわすデータ型 (variant type) *)
type bt = Leaf | Node of int * bt * bt

let rec sumtree t =
  match t with Leaf -> 0 | Node (n, bt1, bt2) -> n + sumtree bt1 + sumtree bt2

let rec maptree f t =
  match t with
  | Leaf -> Leaf
  | Node (n, bt1, bt2) -> Node (f n, maptree f bt1, maptree f bt2)
