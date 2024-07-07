(* フレッシュな識別子 (OCaml 文字列) を生成する関数 (を生成する関数)．
   <p>: プレフィックス，<k>: 種類
   をもとに "<p><k><num>" を生成． *)
let fresh_id_maker p =
  let counter = Hashtbl.create 4 in
  let body k =
    let v = try Hashtbl.find counter k with Not_found -> 0 in
    Hashtbl.add counter k (v + 1);
    Printf.sprintf "%s%s%d" p k v
  in
  body

(* リストxs中の述語pを満たす一つ目の要素の位置を返す *)
let index_of p xs =
  let rec i_of i = function
    | [] -> None
    | x :: _ when p x -> Some i
    | _ :: xs' -> i_of (i + 1) xs'
  in
  i_of 0 xs
