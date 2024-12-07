(* Based on the lecture note at http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html *)

(* Tuareg mode + merlin or ocaml-lsp *)

1 + (2 * 3);;
5 < 8;;

(* OCaml の equality は (=) でチェック *)
5 = 2 || 9 > -5

(* x という名前を 1 + 2 * 3 の評価結果につける．*)
(* x を 1 + 2 * 3 の評価結果に束縛する *)
(* bind x to the result of the valuation of 1 + 2 * 3. *)
(* 型推論 *)
(* type inference *)
let x = 1 + (2 * 3);;

x - 10

let x : int = 1 + (2 * 3)
let x = 4 < 5

(* 関数 *)

(* 関数定義 *)
let average (x, y) = (x + y) / 2;;

(* 関数適用 *)
average (5, 7);;
average (10, 3);;
average @@ (5, 7)

let double n = n + n;;

double 256

let abs n = if n < 0 then -n else n;;

abs (-100);;
abs 20

(* 再帰関数 *)

(* n! = n * (n-1) * ... * 1 *)
(* 1! = 1 *)
(* (n+1)! = (n+1) * n! *)

(* zarith つかうと無限精度の整数が使えます *)
(* opam install zarith *)
let rec fact n = if n = 1 then 1 else n * fact (n - 1);;

fact 5

(* fact 0;; *)

(* let宣言は代入ではない *)

let pi = 3.14

(* pi を定義する *)

let circle_area radius = pi *. radius *. radius;;

(* circle_area 内の pi はさっき定義した pi *)

circle_area 4.0

let pi = 3.00;;

(* pi を再定義しても... *)

circle_area 4.0;;

(* circle_area で使われる pi の値が変化するわけではない．すなわち let による pi の再定義は代入とは違う *)

circle_area pi

let circle_area2 radius = pi *. radius *. radius;;

(* 新たに pi を使う関数を定義したときに，これが使う pi はどこで定義された pi か？ *)

circle_area2 4.0;;

(* let式とスコープ *)

(* スコープ: 変数の有効範囲のこと *)

let n = 5 * 2 in
n + n
;;

(* nのスコープについて説明 *)

(* n;; *)

let x1 = 1 + 1 in
let x2 = x1 + x1 in
let x3 = x2 + x2 in
x3 + x3

(* 関数定義内で let ... in を使えるし *)
let cylinder_vol (r, h) =
  let bottom = circle_area r in
  bottom *. h
;;

(* let ... in で関数定義をすることもできる *)
let cube n = n * n * n in
cube 1 + cube 2 + cube 3

(* cube 3;; *)

(* レコード *)

(* レコード型の定義 *)
type point =
  { x : int
  ; y : int
  }

let origin = { x = 0; y = 0 };;

(* レコードの作成 *)

origin.x

(* レコードから値を取り出す *)

let middle (p1, p2) = { x = average (p1.x, p2.x); y = average (p1.y, p2.y) };;

middle (origin, { x = 4; y = 5 })

let { x = ox; y = oy } = origin

(* こんなふうに値を取り出すこともできる *)

let middle (p1, p2) =
  let { x = p1x; y = p1y } = p1 in
  let { x = p2x; y = p2y } = p2 in
  { x = average (p1x, p2x); y = average (p1y, p2y) }
;;

let middle ({ x = p1x; y = p1y }, { x = p2x; y = p2y }) =
  { x = average (p1x, p2x); y = average (p1y, p2y) }
;;

let get_x { x; _ } = x

(* ヴァリアント型 *)

type furikake =
  | Shake
  | Katsuo
  | Nori
;;

Shake

(* パターンマッチ *)

let isVeggie f =
  match f with
  | Shake -> false
  | Katsuo -> false
  | Nori -> true
;;

isVeggie Shake

(* パターンの網羅性チェック *)

let isVeggie f =
  match f with
  | Shake -> false
  | Nori -> true
;;

(* いろいろなパターン *)

let is_prime_less_than_twenty n =
  (* 定数パターン *)
  match n with
  | 2 -> true
  | 3 -> true
  | 5 -> true
  | 7 -> true
  | 11 -> true
  | 13 -> true
  | 17 -> true
  | 19 -> true
  | _ -> false (* ワイルドカードパターン *)
;;

let is_prime_less_than_twenty n =
  (*  or パターン *)
  match n with
  | 2 | 3 | 5 | 7 | 11 | 13 | 17 | 19 -> true
  | _ -> false
;;

(* 引数のついたヴァリアント *)

type miso =
  | Aka
  | Shiro
  | Awase

type gu =
  | Wakame
  | Tofu
  | Radish

type dish =
  | PorkCutlet (* コンストラクタ *)
  | Soup of
      { m : miso
      ; g : gu
      }
  | Rice of furikake
;;

PorkCutlet;;

(* トンカツ *)
Soup { m = Aka; g = Tofu };;

(* 豆腐赤だし *)
Rice Shake

(* 鮭ふりかけごはん *)

(* Rice;; *)

let isSolid d =
  match d with
  | PorkCutlet -> true
  | Soup m_and_g -> false
  | Rice f -> true
;;

let price_of_dish d =
  match d with
  | PorkCutlet -> 350
  | Soup m_and_g -> 90
  | Rice f ->
    (match f with
     | Shake -> 90
     | Katsuo -> 90
     | Nori -> 80)
;;

let price_of_dish d =
  match d with
  | PorkCutlet -> 350
  | Soup m_and_g -> 90
  | Rice Shake -> 90
  | Rice Katsuo -> 90
  | Rice Nori -> 80
;;

let price_of_dish d =
  match d with
  | PorkCutlet -> 350
  | Soup m_and_g -> 90
  | Rice (Shake | Katsuo) -> 90
  | Rice Nori -> 80
;;

(* 再帰ヴァリアント *)

type menu =
  | Smile
  | Add of
      { d : dish
      ; next : menu
      }

let m1 = Smile

(* 文無し定食 *)
let m2 = Add { d = PorkCutlet; next = m1 }

(* トンカツのみ *)
let m3 = Add { d = Rice Nori; next = m2 }

(* のりふりかけご飯を追加 *)
let m4 = Add { d = Rice Shake; next = m3 }

(* ごはんのおかわりつき *)

(*
   let price_of_menu m =
  match m with
    Smile -> 0
  | Add {d = d1; next = m'} -> ???
;;
*)

let rec price_of_menu m =
  match m with
  | Smile -> 0
  | Add { d = d1; next = m' } -> price_of_dish d1 + price_of_menu m'
;;

(* *)

type 'a mylist =
  | Nil
  | Cons of 'a * 'a mylist

let rec sum ml =
  match ml with
  | Nil -> 0
  | Cons (n, tl) -> n + sum tl
;;

let rec concat ml =
  match ml with
  | Nil -> ""
  | Cons (s, tl) -> s ^ concat tl
;;

concat (Cons ("a", Cons ("b", Nil)))

(* 破壊的に変更が可能なレコードの話 *)

(* 破壊的代入 *)
(* 変数が mutable である *)
(* C とか Java の変数は mutable
   x = 3;
   x = 4;
*)

(* 変数への破壊的代入ができないことを変数が
   immutable であるという． *)

type mutable_point =
  { mutable x : int
  ; mutable y : int
  }

let m_origin = { x = 0; y = 0 }
let f y = m_origin.x + y;;

f 3;;
m_origin.x <- 5;;
f 3;;
m_origin.x;;
m_origin.x <- 2;;
m_origin;;
print_int;;

(* 返り値が unit なのは副作用が重要であるため *)
print_int (5 + 15)

(* メモリ上で何がおこっているかを説明する *)
let p1 = { x = 0; y = 1 };;

(*
   p1 ----> {x=0; y=1}
*)

p1.x <- 2

(*
   p1 ----> {x=2; y=1}
*)

let p2 = p1;;

(*
   p1 ----+
          |---> {x=2; y=1}
   p2 ----+
*)

p2.y <- 3;;

(*
   p1 ----+
          |---> {x=2; y=3}
   p2 ----+
*)

p1.y

(* aliasing *)
(* 同じメモリ上の情報を指す複数の名前が存在すること *)
(* 例えば，この例では p1 も p2 も同じレコードを指している *)

(* 破壊的でないアップデートの構文 *)
let p3 = { p2 with x = 2 };;

(*
   p1 ----+
          |---> {x=2; y=3}
   p2 ----+

   p3 --------> {x=2; y=3}
*)

(*
   let p = {origin with y = 3};; (* 破壊的でないアップデート *)
origin;;
*)

p3.y <- 5;;
p2

(* 参照（ref 型） *)

(* 参照の作成．実態は contents という mutable フィールドを持つレコード *)
let x = ref 1
let y = ref 3.14;;

x := 2;;

(* x.contents <- 2 と同じ *)
!x;;

(* x.contents と同じ / boolean の否定ではない *)
x := !x + 1;;
!x

(* fresh_int : unit -> int *)
let next = ref 0

let fresh_int () =
  let ret = !next in
  next := !next + 1;
  ret
;;

(* 制御構造 *)

(* e1;e2
   e1を評価して，その値を捨てて，e2を評価して，その結果を全体の評価結果とする．
*)

p1.x <- 0;
p2.y <- 4;
print_int p1.y;
100
;;

(* 逐次実行 *)
1 + 1;;
5;;

ignore (1 + 1);
5

let is_positive n =
  if n > 0 then print_string "n is positive\n" else print_string "n is not positive\n"
;;

is_positive 100

let is_positive' n = if n > 0 then print_string "n is positive\n";;

(* then を省略できるのは，unit型の式の場合に限る．*)
is_positive' 100;;
is_positive' (-100)

(* ハマりどころ: セミコロンと if-then-else の結合 *)
(*
   let is_positive n =
   if n > 0 then print_int n; print_string " is positive"
   else print_int n; print_string " isn't positive"
   ;;
*)

(* はまらないように修正するには *)
let is_positive n =
  if n > 0
  then (
    print_int n;
    print_string " is positive")
  else (
    print_int n;
    print_string " isn't positive")
;;

(* begin-end はカッコと同じ *)
(2 + 3) * 10

let is_positive n =
  if n > 0
  then (
    print_int n;
    print_string " is positive")
  else (
    print_int n;
    print_string " isn't positive")
;;

(1 + 2) * 5;;

(* begin 2 + 3 ) * 10;; *)
(* (2 + 3 end * 10;; *)

(* ループ式 *)

for i = 1 to 10 do
  print_int i;
  print_newline () (* ここは unit でなければならない *)
done
;;

let i = ref 1 in
while !i <= 10 do
  print_int !i;
  print_newline ();
  i := !i + 1 (* incr i と書いても良い *)
done

(*** 積み残し ***)

(* 高階関数: 関数を受け取る関数 *)
(* 関数型言語にはだいたい高階関数とか関数を表す値をお気軽に作れる構文が備わっている *)
(* Taken from https://hackmd.io/@aigarashi/r1az0wOHP/%2F8YzCGhsMTQOTk8Zg_ajktQ *)

(* f が表す数列の最初の n+1 項の和をとる関数 *)
(* f は int -> int 型で，f 0, f 1, f 2, ...
   という数列とみなせる *)
let rec sigma (f, n) = if n < 1 then f 0 else f n + sigma (f, n - 1)

(* val sigma : (int -> int) * int -> int = <fun> *)

(* 結合を説明する: 右結合 right associative *)
(* 左結合 left associative *)
(* int -> int -> int = int -> (int -> int) *)
(* (int -> int) -> int *)

let square n = n * n
let cube n = n * n * n
let a = sigma (square, 20)
let b = sigma (cube, 20)

(* anonymous functions *)
let c = sigma ((fun n -> n * n), 20)
let d = sigma ((fun n -> n * n * n), 20);;

(*
   let cube = fun n -> n * n * n
   ;;
*)

fun (x, y) -> (x +. y) /. 2.0;;

(*
   fun c ->
   match c with
   | Nil -> 0
   | Cons(n,tl) -> 1
   ;;
*)

function
| Nil -> 0
| Cons (n, tl) -> 1

(* カリー化 *)

type gender =
  | Male
  | Female

let greeting (gen, name) =
  match gen with
  | Male -> "Hello, Mr. " ^ name
  | Female -> "Hello, Ms. " ^ name
;;

let g1 = greeting (Male, "Poirot")
let g2 = greeting (Female, "Marple")

let curried_greeting gen name =
  match gen with
  | Male -> "Hello, Mr. " ^ name
  | Female -> "Hello, Ms. " ^ name
;;

let greeting_for_men = curried_greeting Male
let greeting_for_women = curried_greeting Female
let g1 = greeting_for_men "Poirot"
let g2 = greeting_for_women "Marple"

let curried_greeting gen name =
  match gen with
  | Male -> "Hello, Mr. " ^ name
  | Female -> "Hello, Ms. " ^ name
;;

let g1 = (curried_greeting Male) "Poirot"
let g2 = curried_greeting Female "Marple";;

(*
   カリー化 currying

   fun (x,y) -> e
   fun x -> fun y -> e

   'a * 'b -> 'c
   'a -> 'b -> 'c
*)

(* リスト *)

[];;
[ 0 ];;
[ 0; 1 ];;
[ 0; 1; 2 ];;
[ 0; 1; 2; 3; 4 ]

let rec create_list n len = if len = 0 then [] else n :: create_list n (len - 1);;

(*
   create_list 5 3
   -->
   5 :: (create_list 5 2)
   -->
   5 :: 5 :: (create_list 5 1)
   -->
   5 :: 5 :: 5 :: (create_list 5 0)
   -->
   5 :: 5 :: 5 :: []
*)

create_list 1 10;;
create_list 1 10000

let rec create_list_tail n len res =
  if len = 0 then res else create_list_tail n (len - 1) (n :: res)
;;

let create_list n len = create_list_tail n len []

(*
   create_list 5 3
   -->
   create_list_tail 5 3 []
   -->
   create_list_tail 5 2 (5::[])
   -->
   create_list_tail 5 1 (5::5::[])
   -->
   create_list_tail 5 0 (5::5::5::[])
   -->
   5 :: 5 :: 5 :: []
*)

let rec sum l =
  match l with
  | [] -> 0
  | hd :: tl -> hd + sum tl
;;

sum (create_list 1 10);;
create_list 1 10 |> sum;;
sum (create_list 1 100);;
sum (create_list 1 100000000)

let rec sum_tail l sum =
  match l with
  | [] -> sum
  | hd :: tl -> sum_tail tl (sum + hd)
;;

sum_tail (create_list_tail 1 10 []) 0;;
sum_tail (create_list_tail 1 100 []) 0;;
sum_tail (create_list_tail 1 100000000 []) 0;;
create_list_tail 1 100000000 [] |> fun l -> sum_tail l 0

(* 多相性 *)

let f x = x;;

f 5;;
f true;;
f (5, true);;
f [ 1; 2; 3; 4; 5 ]

let rec map f l =
  match l with
  | [] -> []
  | hd :: tl -> f hd :: map f tl
;;

map (fun x -> x + 1) [ 1; 2; 3; 4; 5 ];;
map (fun x -> x && true) [ true; false; true; false ];;
map (fun x -> fst x) [ 1, true; 3, false; 7, true ]

(* パターンマッチと匿名関数を組み合わせた構文 *)

let rec map f = function
  | [] -> []
  | hd :: tl -> f hd :: map f tl
;;

map (fun x -> x + 1) [ 1; 2; 3; 4; 5 ];;
map (fun x -> x && true) [ true; false; true; false ];;
map (fun x -> fst x) [ 1, true; 3, false; 7, true ]
