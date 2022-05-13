type ('a, 'b) t = ('a * 'b) list

let empty = []

let is_empty = function
    [] -> true
  | x::xs -> false

let singleton k v = [(k, v)]

let from_list x = x
let to_list x = x

let rec assoc k v = function
    [] -> [(k, v)]
  | (k', v') :: rest ->
      if k == k' then
        (k, v) :: rest
      else
        (k', v') :: assoc k v rest

let rec get k = function
    [] -> None
  | (k', v') :: rest ->
      if k == k' then Some v'
      else get k rest

let merge xs ys =
  List.fold_left (fun zs (k, v) -> assoc k v zs) ys xs

let rec remove k = function
    [] -> []
  | (k', v') :: rest -> if k == k' then rest else (k', v') :: remove k rest

let contains k = List.exists (fun (k', _) -> k == k')

let rec map f = function
    [] -> []
  | (k, v) :: rest -> let (k', v') = f k v in assoc k' v' (map f rest)

let bigmerge ms =
  let rec bm = function
      [] -> []
    | map1 :: rest -> merge map1 (bm rest) in
  bm (MySet.to_list ms)
