type 'a t

exception Not_bound

val empty : 'a t
val extend : Syntax.id -> 'a -> 'a t -> 'a t
val lookup : Syntax.id -> 'a t -> 'a
val map : ('a -> 'b) -> 'a t -> 'b t
val fold_right : ('a -> 'b -> 'b) -> 'a t -> 'b -> 'b

(* NOTE:
   The function prints the internal implementation of type `t`
   (i.e., if the internal implementation of type `t` is `list`, it is printed as `list`).
   This is not a problem when testing, but is undesirable otherwise,
   since the advantage of information hiding is lost.
   Ideally, this functions should only be defined at test time, but I do not yet know how to do this.
   Currently, care should be taken not to call this function from production code.
*)
val show : (Format.formatter -> 'a -> unit) -> 'a t -> string
val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
