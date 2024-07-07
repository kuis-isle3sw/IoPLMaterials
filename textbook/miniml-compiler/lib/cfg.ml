module Set = MySet

exception Error of string

let err s = raise (Error s)

(* ==== 制御フローグラフ(control flow graph)  ==== *)

(* === CFG (control flow graph) は基本ブロックの配列 === *)

(* === 基本ブロック (basic block) === *)
type bblock = {
  mutable labels : Vm.label Set.t;
  stmts : Vm.instr array;
  mutable preds : int Set.t;
  mutable succs : int Set.t;
}

(* Vm.instrと合わせ，プログラムポイントの指定に用いる
   BEFORE: instrの直前
   AFTER:  instrの直後 *)
type side = BEFORE | AFTER

(* ==== 各種表示 ==== *)

let string_of_labels sep lbls =
  if Set.is_empty lbls then "" else String.concat sep (Set.to_list lbls) ^ ":"

(* 端末上で見やすい表現の文字列(ノード間のエッジは見えない)
   (stmt -> side -> string) option -> bblock array -> string *)
let string_of_cfg str_of_prop cfg =
  let fmt_stmt s = Vm.string_of_instr "  " "\t" s ^ "\n" in
  let fmt_prop s p =
    match str_of_prop with None -> "" | Some f -> "  {" ^ f s p ^ "}\n"
  in
  String.concat "\n"
    (List.map
       (fun bb ->
         let lbl_str =
           if Set.is_empty bb.labels then ""
           else string_of_labels ", " bb.labels ^ "\n"
         in
         let body_str =
           fmt_prop bb.stmts.(0) BEFORE
           ^ String.concat ""
               (List.map
                  (fun stmt -> fmt_stmt stmt ^ fmt_prop stmt AFTER)
                  (Array.to_list bb.stmts))
         in
         lbl_str ^ body_str)
       (Array.to_list cfg))

let rec flatmap_of_string f s =
  if String.length s = 0 then ""
  else
    let c = String.get s 0 in
    let s' = String.sub s 1 (String.length s - 1) in
    f c ^ flatmap_of_string f s'

(* graphviz への入力(文字列)に変換．
   label -> (stmt -> side -> string) option -> bblock array -> string *)
let dot_of_cfg lbl str_of_prop cfg =
  let escape_char = function
    | '<' -> "\\<"
    | '>' -> "\\>"
    | '{' -> "\\{"
    | '}' -> "\\}"
    | c -> String.make 1 c
  in
  let escape s = flatmap_of_string escape_char s in
  let fmt_stmt s = escape (Vm.string_of_instr "" "  " s ^ "\\l") in
  let fmt_prop s p =
    match str_of_prop with None -> "" | Some f -> escape ("{" ^ f s p ^ "}\\l")
  in
  let bblock_to_node i bb =
    let lbl_str =
      if Set.is_empty bb.labels then ""
      else string_of_labels ", " bb.labels ^ "\\l|"
    in
    let body_str =
      fmt_prop bb.stmts.(0) BEFORE
      ^ String.concat ""
          (List.map
             (fun stmt -> fmt_stmt stmt ^ fmt_prop stmt AFTER)
             (Array.to_list bb.stmts))
    in
    lbl ^ string_of_int i ^ " [label=\"{" ^ lbl_str ^ body_str ^ "}\"];\n"
  in
  let bblock_to_edge i bb =
    String.concat "  "
      (List.map
         (fun j ->
           lbl ^ string_of_int i ^ " -> " ^ lbl ^ string_of_int j ^ "\n")
         (Set.to_list bb.succs))
  in
  "  "
  ^ String.concat "  " (List.mapi bblock_to_node (Array.to_list cfg))
  ^ "\n  "
  ^ String.concat "  " (List.mapi bblock_to_edge (Array.to_list cfg))

let dot_of_cfgs str_of_prop cfgs =
  "digraph CFG {\n"
  ^ "  node [shape=record fontname=\"courier\"]\n"
  ^ String.concat "\n"
      (List.map (fun (lbl, cfg) -> dot_of_cfg lbl str_of_prop cfg) cfgs)
  ^ "}\n"

let emit_graph lbl dot_str =
  let dot_file = "cfg_" ^ lbl ^ ".dot" in
  let pdf_file = "cfg_" ^ lbl ^ ".pdf" in
  let ochan = open_out dot_file in
  output_string ochan dot_str;
  close_out ochan;
  let _ = Sys.command ("dot -Tpdf -o " ^ pdf_file ^ " " ^ dot_file) in
  let _ = Sys.command ("open " (* for Mac *) ^ pdf_file) in
  (* let _ = Sys.command ("evince " (* for Linux *) ^ pdf_file) in *)
  (* let _ = Sys.command ("cygstart.exe " (* for Cygwin *) ^ pdf_file) in *)
  ()

(* === アクセス関数 === *)

(* CFGに含まれる全ての文を一つの配列にして返す *)
let all_stmts cfg =
  Array.concat (List.map (fun bb -> bb.stmts) (Array.to_list cfg))

(* CFG中のtgt文の位置(インデックスの組)を返す
   CFG, stmt -> (bblockインデックス, stmtインデックス) *)
let find_stmt cfg tgt =
  (*  基本ブロックbb中のtgtの位置(インデックス)のリストを返す *)
  let find_in_bb bb =
    List.map
      (fun (idx, stmt) -> idx)
      (List.filter
         (fun (idx, stmt) -> stmt == tgt)
         (List.mapi (fun idx stmt -> (idx, stmt)) (Array.to_list bb.stmts)))
  in
  let rs =
    List.concat
      (List.mapi
         (fun i bb -> List.map (fun j -> (i, j)) (find_in_bb bb))
         (Array.to_list cfg))
  in
  match rs with
  | [] -> err "no stmt found"
  | [ r ] -> r
  | _ -> err "multiple stmts found"

(* stmt の predecessors を返す．
   CFG, stmt -> stmtのリスト *)
let preds cfg stmt =
  let b_idx, s_idx = find_stmt cfg stmt in
  let bb = cfg.(b_idx) in
  let stmts = bb.stmts in
  if b_idx = 0 && s_idx = 0 then (* BEGIN *)
    []
  else if s_idx = 0 then
    (* 基本ブロックの先頭の文 *)
    List.map
      (fun pb_idx ->
        let pb = cfg.(pb_idx) in
        let stmts = pb.stmts in
        stmts.(Array.length stmts - 1))
      (Set.to_list bb.preds)
  else (* 基本ブロックの先頭以外の文 *)
    [ stmts.(s_idx - 1) ]

(* stmt の successors を返す．
   CFG, stmt -> stmt のリスト *)
let succs cfg stmt =
  let b_idx, s_idx = find_stmt cfg stmt in
  let bb = cfg.(b_idx) in
  let stmts = bb.stmts in
  if b_idx = Array.length cfg - 1 && s_idx = Array.length stmts - 1 then []
    (* END *)
  else if s_idx = Array.length stmts - 1 then
    (* 基本ブロックの末尾の文 *)
    List.map
      (fun sb_idx ->
        let sb = cfg.(sb_idx) in
        let stmts = sb.stmts in
        stmts.(0))
      (Set.to_list bb.succs)
  else (* 基本ブロックの末尾以外の文 *)
    [ stmts.(s_idx + 1) ]

(* === CFG構築 === *)

(* stmt 中の各ラベルを直後の命令へくっつける．
   BEGIN と END を先頭と末尾に追加．
   先頭ラベル -> 命令のリスト -> ラベル付き文のリスト *)
let coalesce_label lbl instrs =
  let lis =
    List.fold_left
      (fun stmts instr ->
        match stmts with
        | [] -> (
            match instr with
            | Vm.Label l -> [ (Set.singleton l, None) ]
            | _ -> [ (Set.empty, Some instr) ])
        | stmt :: stmts' -> (
            match (instr, stmt) with
            | Vm.Label l, (lbls, None) -> (Set.insert l lbls, None) :: stmts'
            | Vm.Label l, (_, Some _) -> (Set.singleton l, None) :: stmts
            | _, (lbls, None) -> (lbls, Some instr) :: stmts'
            | _, (_, Some _) -> (Set.empty, Some instr) :: stmts))
      [] instrs
  in
  [ (Set.singleton lbl, Vm.BEGIN lbl) ]
  @ List.rev
      (List.map
         (function
           | lbls, Some instr -> (lbls, instr)
           | _, None -> err "ill formed stmts")
         lis)
  @ [ (Set.empty, Vm.END lbl) ]

(* 基本ブロックの先頭にあたるラベル付き文をleaderと呼ぶ．
   leader集合を見つけて返す．
   ラベル付き文のリスト -> leader集合 *)
let find_leaders lstmts =
  let find_target lbl =
    List.find (function lbls, _ -> Set.member lbl lbls) lstmts
  in
  let _, r =
    List.fold_left
      (fun (is_leader, leaders) stmt ->
        let leaders' = if is_leader then Set.insert stmt leaders else leaders in
        match snd stmt with
        | Vm.BEGIN _ -> (true, leaders')
        | Vm.END _ -> (false, Set.insert stmt leaders')
        | Vm.Move _ | Vm.BinOp _ | Vm.Call _ | Vm.Malloc _ | Vm.Read _ ->
            (false, leaders')
        | Vm.BranchIf (_, lbl) -> (true, Set.insert (find_target lbl) leaders')
        | Vm.Goto lbl -> (true, Set.insert (find_target lbl) leaders')
        | Vm.Return _ -> (true, leaders')
        | Vm.Label _ -> err "no such case")
      (true, Set.empty) lstmts
  in
  r

(* 基本ブロックのコンストラクタ
   ラベル付き文のリスト -> エッジ情報が未設定のbblock *)
let make_bblock lstmts =
  match lstmts with
  | [] -> err "make_bblock: invalid argument."
  | (lbls, i) :: lstmts' ->
      {
        labels = lbls;
        stmts = Array.of_list (List.map snd lstmts);
        preds = Set.empty;
        succs = Set.empty;
      }

(* leader情報をつかってstmtリストを基本ブロックに分割
   stmt list -> leader集合(stmt Set.t) -> bblock list *)
let split stmts leaders =
  List.rev
    (List.map
       (fun bb -> make_bblock (List.rev bb))
       (List.fold_left
          (fun bbs stmt ->
            if Set.member stmt leaders then [ stmt ] :: bbs
            else
              match bbs with
              | bb :: bbs' -> (stmt :: bb) :: bbs'
              | [] -> err "no such case.")
          [] stmts))

(* 制御フローに従い，基本ブロック間にエッジを張る
   bbリスト -> used_lbls -> エッジの張られたbb配列(CFG)
   used_lbls: 実際に使用されたラベルを貯めるキュー *)
let set_edges bbs used_lbls =
  let add_pred bb p =
    (* bbのpredsにpを追加 *)
    bb.preds <- Set.insert p bb.preds
  in
  let add_succ bb s =
    (* bbのsuccsにsを追加 *)
    bb.succs <- Set.insert s bb.succs
  in
  let bbv = Array.of_list bbs in
  (* bbvのi,j番目の基本ブロック間に双方向のエッジを張る *)
  let add_edge i j =
    add_succ bbv.(i) j;
    add_pred bbv.(j) i
  in
  (* 先頭ラベルにlblを含む基本ブロックを探し，そのインデックスを返す．
     さらに，見つかれば，使用ラベル集合u-lblsにそのラベルを追加 *)
  let labels_to_index_map =
    List.mapi (fun i lbls -> (lbls, i)) (List.map (fun bb -> bb.labels) bbs)
  in
  let find_target_bblock lbl =
    try
      let _, idx =
        List.find (fun (lbls, idx) -> Set.member lbl lbls) labels_to_index_map
      in
      Queue.add lbl used_lbls;
      idx
    with Not_found -> err ("target label not found: " ^ lbl)
  in
  (* bblockリスト(とそのインデックス)を先頭から順に処理 *)
  List.iteri
    (fun i bb ->
      match bb.stmts.(Array.length bb.stmts - 1) with
      | Vm.BEGIN _ -> add_edge i (i + 1)
      | Vm.END _ -> ()
      | Vm.Move _ | Vm.BinOp _ | Vm.Call _ | Vm.Malloc _ | Vm.Read _ ->
          add_edge i (i + 1)
      | Vm.Label _ -> err "no such case"
      | Vm.BranchIf (_, lbl) ->
          add_edge i (find_target_bblock lbl);
          add_edge i (i + 1)
      | Vm.Goto lbl -> add_edge i (find_target_bblock lbl)
      | Vm.Return _ -> add_edge i (List.length bbs - 1))
    bbs;
  bbv

(* 各基本ブロックの先頭ラベル集合から未使用ラベルを取り除く
   bblock配列 -> ラベル集合 -> bblock配列 *)
let gc_label cfg used_lbls =
  Array.iter
    (fun bb ->
      bb.labels <-
        Set.from_list
          (List.filter
             (fun lbl -> Set.member lbl used_lbls)
             (Set.to_list bb.labels)))
    cfg;
  cfg

(* label -> VM.instr list -> CFG (bblock配列) *)
let vm_to_cfg lbl instrs =
  let stmts = coalesce_label lbl instrs in
  let leaders = find_leaders stmts in
  let bbs = split stmts leaders in
  let used_labels = Queue.create () in
  let bbv = set_edges bbs used_labels in
  (* gc_label bbv (Queue.fold (fun s l -> Set.insert l s)
     Set.empty used_labels) *)
  bbv

(* visualize graph *)
let display_cfg cfgs string_of_prop =
  emit_graph "tmp"
    (dot_of_cfgs string_of_prop (List.map (fun (lbl, cfg) -> (lbl, cfg)) cfgs))

(* entry point *)
let build vmcode =
  List.map
    (fun (Vm.ProcDecl (lbl, _, body)) -> (lbl, vm_to_cfg lbl body))
    vmcode
