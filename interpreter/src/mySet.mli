type 'a t

val empty : 'a t
val singleton : 'a -> 'a t
val from_list : 'a list -> 'a t
val to_list : 'a t -> 'a list
val insert : 'a -> 'a t -> 'a t
val union : 'a t -> 'a t -> 'a t
val remove : 'a -> 'a t -> 'a t
val diff : 'a t -> 'a t -> 'a t
val member : 'a -> 'a t -> bool

val map : ('a -> 'b) -> 'a t -> 'b t
val bigunion : 'a t t -> 'a t
