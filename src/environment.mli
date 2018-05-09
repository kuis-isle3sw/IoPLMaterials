(* t は環境を表す型．
   'a は変数が束縛される先の値の型． *)
type 'a t

exception Not_bound

val empty : 'a t
val extend : Syntax.id -> 'a -> 'a t -> 'a t
val lookup : Syntax.id -> 'a t -> 'a
val map : ('a -> 'b) -> 'a t -> 'b t
val fold_right : ('a -> 'b -> 'b) -> 'a t -> 'b -> 'b
