type layout
type doc

val nil : doc
val line : doc
val text : string -> doc
val nest : int -> doc -> doc
val group : doc -> doc
val (<*>) : doc -> doc -> doc

val layouts : doc -> layout list
val pretty : int -> doc -> layout

val layout : layout -> string
val (<+>) : doc -> doc -> doc
val (<|>) : doc -> doc -> doc
val spread : doc list -> doc
val stack : doc list -> doc
