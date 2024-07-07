module Set = MySet
module Map = MyMap

exception Error of string

let err s = raise (Error s)

type direction = FORWARD | BACKWARD
type prop_ordering = LT | EQ | GT | NO

(* プロパティ'a を求める解析器を表すデータ型 *)
type 'a analysis = {
  direction : direction;
  transfer : 'a -> Vm.instr -> 'a;
  compare : 'a -> 'a -> prop_ordering;
  lub : 'a -> 'a -> 'a;
  bottom : 'a;
  init : 'a;
  to_str : 'a -> string;
}

(* 解析結果．プログラムポイント(instr * BEFORE/AFTER) -> プロパティ *)
type 'a result = { before : (Vm.instr, 'a) Map.t; after : (Vm.instr, 'a) Map.t }

(* 解析結果から指定のプログラムポイントのプロパティを取得 *)
let get_property rslt stmt side =
  match
    Map.get stmt
      (match side with Cfg.BEFORE -> rslt.before | Cfg.AFTER -> rslt.after)
  with
  | Some p -> p
  | None -> err ("property not found: " ^ Vm.string_of_instr "" "\t" stmt)

(* データフロー解析を実行 *)
let solve anlys cfg =
  (* プロパティ辞書から文sに対応するプロパティを取得．なければbottomを返す *)
  let get_prop m s =
    match Map.get s m with None -> anlys.bottom | Some x -> x
  in
  (* キューwlが空になるまでプロパティ辞書entries, exitsの更新を繰り返す．
     directionがFORWARDの場合，entriesは直前(BEFORE)，exitsは直後(AFTER)．
     BACKWARDの場合は逆．
     wlが空になった時点のentries, exitsが不動点，すなわち解析結果．
     wlの各要素は (stmt, プロパティ)．stmtの直前(直後)のプロパティへの
     追加を表す． *)
  let rec fixed_point wl entries exits =
    if Queue.is_empty wl then
      match anlys.direction with
      | FORWARD -> { before = entries; after = exits }
      | BACKWARD -> { before = exits; after = entries }
    else
      let stmt, prop = Queue.take wl in
      let old_entry_prop = get_prop entries stmt in
      (* 追加されるプロパティとの least upper bound を計算 *)
      let new_entry_prop = anlys.lub old_entry_prop prop in
      (* 差分の有無で場合分け *)
      match anlys.compare new_entry_prop old_entry_prop with
      | EQ -> fixed_point wl entries exits
      | GT -> (
          let old_exit_prop = get_prop exits stmt in
          let new_exit_prop = anlys.transfer new_entry_prop stmt in
          (* 差分の有無で場合分け *)
          match anlys.compare new_exit_prop old_exit_prop with
          | EQ -> fixed_point wl (Map.assoc stmt new_entry_prop entries) exits
          | GT ->
              List.iter (* wlにsuccs (preds)を追加 *)
                (fun stmt -> Queue.add (stmt, new_exit_prop) wl)
                ((match anlys.direction with
                 | FORWARD -> Cfg.succs
                 | BACKWARD -> Cfg.preds)
                   cfg stmt);
              fixed_point wl
                (Map.assoc stmt new_entry_prop entries)
                (Map.assoc stmt new_exit_prop exits)
          | _ -> err "transfer not monotone.")
      | _ -> err "lub operation not adequate."
  in
  let stmts = Cfg.all_stmts cfg in
  let stmts' =
    match anlys.direction with
    | FORWARD -> stmts
    | BACKWARD -> Array.of_list (List.rev (Array.to_list stmts))
  in
  (* entries, exitsの初期値(すべての文のプロパティがbottom) *)
  let init_prop =
    Array.fold_left
      (fun ip stmt -> Map.assoc stmt anlys.bottom ip)
      Map.empty stmts'
  in
  let worklist = Queue.create () in
  Queue.add (stmts'.(0), anlys.init) worklist;
  fixed_point worklist init_prop init_prop
