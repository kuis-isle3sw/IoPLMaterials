(* Based on the lecture note at http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html *)

1 + 2 * 3;;

5 < 8;;

5 = 2 || 9 > -5;;

let x = 1 + 2 * 3;;

x - 10;;

let x : int = 1 + 2 * 3;;

let x = 4 < 5;;

(* 関数 *)

let average(x,y) = (x+y) / 2;;

average(5,7);;

average(10,3);;

let double n = n + n;;

double 256;;

let abs n =
  if n < 0 then -n else n;;

abs(-100);;

abs 20;;

(* 再帰関数 *)

let rec fact n =
  if n = 1 then 1
  else n * fact (n-1)
;;

fact 5;;

(* fact 0 *)

(* let宣言は代入ではない *)

let pi = 3.14;; (* pi を定義する *)

let circle_area radius = pi *. radius *. radius;; (* circle_area 内の pi はさっき定義した pi *)

circle_area 4.0;;

let pi = 3.00;; (* pi を再定義しても... *)

circle_area 4.0;; (* circle_area で使われる pi の値が変化するわけではない．すなわち let による pi の再定義は代入とは違う *)

circle_area pi;;

let circle_area2 radius = pi *. radius *. radius;; (* 新たに pi を使う関数を定義したときに，これが使う pi はどこで定義された pi か？ *)

circle_area2 4.0;;

(* let式とスコープ *)

let n = 5 * 2 in n + n;; (* nのスコープについて説明 *)

(* n;; *)

let x1 = 1 + 1 in
let x2 = x1 + x1 in
let x3 = x2 + x2 in
x3 + x3;;

let cylinder_vol(r,h) = (* 関数定義内で let ... in を使えるし *)
  let bottom = circle_area r in
  bottom *. h;;

let cube n = n * n * n in　(* let ... in で関数定義をすることもできる *)
cube 1 + cube 2 + cube 3;;

(* cube;; *)

(* レコード *)

type point = { x : int; y : int };; (* レコード型の定義 *)

let origin = { x = 0; y = 0 };; (* レコードの作成 *)

origin.x;; (* レコードから値を取り出す *)

let middle(p1,p2) =
  { x = average(p1.x,p2.x); y = average(p1.y,p2.y) }
;;

middle(origin, {x=4; y=5});;

let {x = ox; y = oy} = origin;; (* こんなふうに値を取り出すこともできる *)

let middle(p1,p2) =
  let {x = p1x; y = p1y} = p1 in
  let {x = p2x; y = p2y} = p2 in
  {x = average(p1x,p2x); y = average(p1y,p2y) };;

let middle({x = p1x; y = p1y}, {x = p2x; y = p2y}) =
  {x = average(p1x,p2x); y = average(p1y,p2y)}
;;

let get_x {x} = x;; 

(* ヴァリアント型 *)

type furikake = Shake | Katsuo | Nori;;

Shake;;

(* パターンマッチ *)

let isVeggie f =
  match f with
    Shake -> false
  | Katsuo -> false
  | Nori -> true
;;

isVeggie Shake;;

(* パターンの網羅性チェック *)

let isVeggie f =
    match f with
      Shake -> false
    | Nori -> true
;;

(* いろいろなパターン *)

let is_prime_less_than_twenty n = (* 定数パターン *)
  match n with
    2 -> true
  | 3 -> true
  | 5 -> true
  | 7 -> true
  | 11 -> true
  | 13 -> true
  | 17 -> true
  | 19 -> true
  | _ -> false (* ワイルドカードパターン *)
;;

let is_prime_less_than_twenty n = (*  or パターン *)
  match n with
    2 | 3 | 5 | 7 | 11 | 13 | 17 | 19 -> true
  | _ -> false
;;

(* 引数のついたヴァリアント *)

type miso = Aka | Shiro | Awase;;
type gu = Wakame | Tofu | Radish;;
type dish = PorkCutlet | Soup of {m: miso; g: gu} | Rice of furikake;;

PorkCutlet;;                              (* トンカツ *)
Soup {m = Aka; g = Tofu};;              (* 豆腐赤だし *)
Rice Shake;;                            (* 鮭ふりかけごはん *)

(* Rice;; *)

let isSolid d =
  match d with
    PorkCutlet -> true
  | Soup m_and_g -> false
  | Rice f -> true
;;

let price_of_dish d = 
  match d with
    PorkCutlet -> 350
  | Soup m_and_g -> 90
  | Rice f -> (match f with Shake -> 90 | Katsuo -> 90 | Nori -> 80)
;;

let price_of_dish d = 
  match d with
    PorkCutlet -> 350
  | Soup m_and_g -> 90
  | Rice Shake -> 90
  | Rice Katsuo -> 90 
  | Rice Nori -> 80
;;

let price_of_dish d = 
  match d with
    PorkCutlet -> 350
  | Soup m_and_g -> 90
  | Rice (Shake | Katsuo) -> 90 
  | Rice Nori -> 80
;;

(* 再帰ヴァリアント *)

type menu = Smile | Add of {d: dish; next: menu};;

let m1 = Smile;;                            (* 文無し定食 *)
let m2 = Add {d = PorkCutlet; next= m1};;   (* トンカツのみ *)
let m3 = Add {d = Rice Nori; next= m2};;    (* のりふりかけご飯を追加 *)
let m4 = Add {d = Rice Shake; next= m3};;   (* ごはんのおかわりつき *)

(*
let price_of_menu m =
  match m with 
    Smile -> 0
  | Add {d = d1; next = m'} -> ???
;;
*)

let rec price_of_menu m =
  match m with 
    Smile -> 0
  | Add {d = d1; next = m'} -> price_of_dish d1 + price_of_menu m'
;;

(* 破壊的に変更が可能なレコードの話 *)

let p = {origin with y = 3};; (* 破壊的でないアップデート *)
origin;;

type mutable_point = {mutable x : int; mutable y : int; };;
let m_origin = {x = 0; y = 0};;

m_origin.x <- 2;;
m_origin;;

print_int;; (* 返り値が unit なのは副作用が重要であるため *)
print_int (5+15);;

let p1 = {x = 0; y = 1};; (* メモリ上で何がおこっているかを説明する *)
p1.x <- 2;;
let p2 = p1;;
p2.y <- 3;;
p1.y;;
let p3 = {p2 with x = 2};;

(* 参照（ref 型） *)

let x = ref 1;; (* 参照の作成．実態は contents という mutable フィールドを持つレコード *)
let y = ref 3.14;;
x := 2;;  (* x.contents <- 2 と同じ *)
!x;;  (* x.contents と同じ / boolean の否定ではない *)
x := !x + 1;;
!x;;

(* 制御構造 *)

p1.x <- 0; p2.y <- 4; print_int p1.y; 100 (* 逐次実行 *)
1+1; 5;;
ignore(1+1); 5;;

let is_positive n =
  if n > 0 then print_string "n is positive\n"
  else print_string "n is not positive\n";;
is_positive 100;;

let is_positive' n =
  if n > 0 then print_string "n is positive\n";; (* then を省略できるのは，unit型の式の場合に限る．*)
is_positive' 100;;
is_positive' (-100);;

(*
ハマりどころ: セミコロンと if-then-else の結合
let is_positive n = 
  if n > 0 then print_int n; print_string " is positive"
  else print_int n; print_string " isn't positive";;
*)

(* はまらないように修正するには *)
let is_positive n = 
  if n > 0 then
    begin
      print_int n;
      print_string " is positive"
    end
  else print_int n; print_string " isn't positive";;

is_positive 100;;

let is_positive n = 
  if n > 0 then
    begin
      print_int n;
      print_string " is positive"
    end
  else 
    begin
      print_int n;
      print_string " isn't positive"
    end;;

(* begin-end はカッコと同じ *)
begin 2 + 3 end * 10;;

let is_positive n = 
  if n > 0 then (
    print_int n;
    print_string " is positive"
  ) else (
    print_int n;
    print_string " isn't positive"
  );;

begin 1 + 2 end * 5;;

begin 2 + 3 ) * 10;;
(2 + 3 end * 10;;

(* ループ式 *)

for i = 1 to 10 do
  print_int i; print_newline() (* ここは unit でなければならない *)
done;;

let i = ref 1 in
while !i <= 10 do
  print_int !i; print_newline (); i := !i + 1 (* incr i と書いても良い *)
done
;;


(*** 積み残し ***)

(* 高階関数 *)
(* Taken from https://hackmd.io/@aigarashi/r1az0wOHP/%2F8YzCGhsMTQOTk8Zg_ajktQ *)

let rec sigma(f, n) =
  if n < 1 then f 0
  else f n + sigma(f, n-1)
;;

(* val sigma : (int -> int) * int -> int = <fun> *)
(* 結合を説明する *)

let square n = n * n
let cube n = n * n * n
let a = sigma(square, 20)
let b = sigma(cube, 20)

(* anonymous functions *)
let c = sigma ((fun n -> n*n), 20)
let d = sigma ((fun n -> n*n*n), 20)

let cube = fun n -> n * n * n
;;
fun (x, y) -> (x +. y) /. 2.0;;

(* カリー化 *)

type gender = Male | Female
              
let greeting(gen, name) =
  match gen with
    Male ->   "Hello, Mr. " ^ name
  | Female -> "Hello, Ms. " ^ name
              
let g1 = greeting(Male,   "Poirot")
let g2 = greeting(Female, "Marple")
    
let curried_greeting gen = fun name ->
  match gen with
    Male ->   "Hello, Mr. " ^ name
  | Female -> "Hello, Ms. " ^ name
              
let greeting_for_men = curried_greeting Male
let greeting_for_women = curried_greeting Female
    
let g1 = greeting_for_men "Poirot"
let g2 = greeting_for_women "Marple"

let curried_greeting gen name =
  match gen with
    Male ->   "Hello, Mr. " ^ name
  | Female -> "Hello, Ms. " ^ name

let g1 = (curried_greeting Male) "Poirot"
let g2 = curried_greeting Female "Marple"
;;

(* リスト *)

[];;
0::[];;
0::1::[];;
0::1::2::[]
[0; 1; 2; 3; 4];;

let rec create_list n len =
  if len = 0 then []
  else
    n :: (create_list n (len-1))
;;

let rec sum l =
  match l with
  | [] -> 0
  | hd::tl -> hd + sum tl
;;

let rec sum_tail l sum =
  match l with
  | [] -> sum
  | hd::tl -> sum_tail l (sum + hd)
;;

let rec create_list_tail n len res =
  if len = 0 then res
  else
    create_list_tail n (len-1) (n::res)
;;


(* 多相性 *)
