(* フレッシュな識別子 (OCaml 文字列) を生成する関数 (を生成する関数)．
   <p>: プレフィックス，<k>: 種類
   をもとに "<p><k><num>" を生成． *)
let fresh_id_maker p =
  let counter = Hashtbl.create 4 in
  let body k =
    let v = try Hashtbl.find counter k with Not_found -> 0 in
      Hashtbl.add counter k (v + 1);
      Printf.sprintf "%s%s%d" p k v
  in body
