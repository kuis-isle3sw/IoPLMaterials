type ('a, 'b) t

val empty : ('a, 'b) t
val is_empty : ('a, 'b) t -> bool
val singleton : 'a -> 'b -> ('a, 'b) t
val from_list : ('a * 'b) list -> ('a, 'b) t
val to_list : ('a, 'b) t -> ('a * 'b) list
val assoc : 'a -> 'b -> ('a, 'b) t -> ('a, 'b) t
val get : 'a -> ('a, 'b) t -> 'b option
val merge : ('a, 'b) t -> ('a, 'b) t -> ('a, 'b) t
val remove : 'a -> ('a, 'b) t -> ('a, 'b) t
val contains : 'a -> ('a, 'b) t -> bool
val map : ('a -> 'b -> 'a * 'b) -> ('a, 'b) t -> ('a, 'b) t
val bigmerge : ('a, 'b) t MySet.t -> ('a, 'b) t
