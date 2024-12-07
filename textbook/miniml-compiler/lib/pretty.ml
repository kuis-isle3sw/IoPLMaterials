type layout = string

type doc =
  | Nil
  | Line
  | Text of string
  | Nest of int * doc
  | Group of doc
  | Append of doc * doc

let nil = Nil
let line = Line
let text s = Text s
let nest i d = Nest (i, d)
let group d = Group d
let ( <*> ) d d' = Append (d, d')

(* flatten : doc -> doc *)
let rec flatten = function
  | Nil -> Nil
  | Line -> Text " "
  | Text s -> Text s
  | Nest (_, d) -> flatten d
  | Group d -> flatten d
  | Append (d, d') -> Append (flatten d, flatten d')
;;

(* layr : (int * doc) list -> doc list *)
let rec layr = function
  | [] -> [ "" ]
  | (i, Nil) :: ids -> layr ids
  | (i, Line) :: ids -> List.map (fun l -> "\n" ^ String.make i ' ' ^ l) (layr ids)
  | (i, Text s) :: ids -> List.map (fun l -> s ^ l) (layr ids)
  | (i, Nest (j, d)) :: ids -> layr ((i + j, d) :: ids)
  | (i, Group d) :: ids -> layr ((i, flatten d) :: ids) @ layr ((i, d) :: ids)
  | (i, Append (d, d')) :: ids -> layr ((i, d) :: (i, d') :: ids)
;;

let layouts d = layr [ 0, d ]

let rec fits r l =
  if r < 0
  then false
  else if l = ""
  then true
  else if String.get l 0 = '\n'
  then true
  else fits (r - 1) (String.sub l 1 (String.length l - 1))
;;

let better r lx ly = if fits r lx then lx else ly

let pretty w d =
  let rec best r = function
    | [] -> ""
    | (i, Nil) :: ids -> best r ids
    | (i, Line) :: ids -> "\n" ^ String.make i ' ' ^ best (w - i) ids
    | (i, Text s) :: ids -> s ^ best (r - String.length s) ids
    | (i, Nest (j, d)) :: ids -> best r ((i + j, d) :: ids)
    | (i, Group d) :: ids ->
      better r (best r ((i, flatten d) :: ids)) (best r ((i, d) :: ids))
    | (i, Append (d, d')) :: ids -> best r ((i, d) :: (i, d') :: ids)
  in
  best w [ 0, d ]
;;

(* layout: layout -> string *)
let layout s = s
let ( <+> ) d d' = d <*> text " " <*> d'
let ( <|> ) d d' = d <*> line <*> d'
let spread ds = List.fold_right ( <+> ) ds nil
let stack ds = List.fold_right ( <|> ) ds nil
