open Vm
open Dfa
module Set = MySet

(* ==== vars: 変数名の集合 ==== *)

let dummy = Local (-1)
let bottom = Set.empty

let compare left right =
  if Set.is_empty (Set.diff left right) then
    if Set.is_empty (Set.diff right left) then EQ else LT
  else if Set.is_empty (Set.diff right left) then GT
  else NO

let lub = Set.union

let string_of_vars vs =
  String.concat ", "
    (List.sort String.compare
       (List.map Vm.string_of_operand
          (List.filter (fun v -> v <> dummy) (Set.to_list vs))))

let filter_vars vs =
  Set.from_list
    (List.filter
       (fun v ->
         match v with Param _ | Local _ -> true | Proc _ | IntV _ -> false)
       (Set.to_list vs))

let transfer entry_vars stmt =
  let gen vs =
    lub
      (filter_vars
         (match stmt with
         | Move (dst, src) -> Set.singleton src
         | BinOp (dst, op, l, r) -> Set.from_list [ l; r ]
         | BranchIf (c, l) -> Set.singleton c
         | Call (dst, tgt, args) -> Set.insert tgt (Set.from_list args)
         | Return v -> Set.singleton v
         | Malloc (dst, vs) -> Set.from_list vs
         | Read (dst, v, i) -> Set.singleton v
         | _ -> Set.empty))
      vs
  in
  let kill vs =
    match stmt with
    | Move (dst, _)
    | BinOp (dst, _, _, _)
    | Call (dst, _, _)
    | Malloc (dst, _)
    | Read (dst, _, _) ->
        Set.remove (Local dst) vs
    | _ -> vs
  in
  gen (kill entry_vars)

let make () =
  {
    direction = BACKWARD;
    transfer;
    compare;
    lub;
    bottom;
    (* 不動点反復を回すためのdirty hack *)
    init = Set.singleton dummy;
    to_str = string_of_vars;
  }
