module Set = MySet
module Map = MyMap

exception Error of string

let err s = raise (Error s)

(* 複数の CFG を解析し，結果を1つの結果にマージ
   結果は Vm.instr をキーとするマップ(の組)であり，各キーは
   (equalityではなく) identityにより比較されることに注意 *)
let analyze_cfg anlys cfgs =
  let results = List.map (fun (_, cfg) -> Dfa.solve anlys cfg) cfgs in
  { Dfa.before = Map.bigmerge (Set.from_list (List.map (fun r -> r.Dfa.before) results))
  ; Dfa.after = Map.bigmerge (Set.from_list (List.map (fun r -> r.Dfa.after) results))
  }
;;

(* 各種最適化をここに追加 *)
let opt lv_results vmcode = vmcode

(* レジスタ機械コードの生成．nregは利用可能な汎用物理レジスタの個数 *)
let gen_regcode nreg lv_results vmcode = Reg.trans nreg lv_results vmcode

let optimize is_disp_cfg nreg vmcode =
  (* CFGを構築 *)
  let cfgs = Cfg.build vmcode in
  (* 生存変数解析器を生成 *)
  let lv = Live.make () in
  (* 生存変数解析を実行 *)
  let lv_results = analyze_cfg lv cfgs in
  (* 解析結果を表示 *)
  if is_disp_cfg
  then (
    let string_of_prop stmt side =
      lv.Dfa.to_str (Dfa.get_property lv_results stmt side)
    in
    Cfg.display_cfg cfgs (Some string_of_prop));
  (* その他，各種最適化 *)
  let vmcode' = opt lv_results vmcode in
  (* 生存変数情報を使って仮想機械コードをレジスタ機械コードへ変換 *)
  let regcode = gen_regcode nreg lv_results vmcode' in
  regcode
;;
