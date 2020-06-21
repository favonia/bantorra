open Basis.JSON

type path = string list
type t
val init : root:string -> anchor_path:string -> t
val locate_anchor_and_init : anchor_path:string -> suffix:string -> string -> t * path
val save_cache : t -> unit

val iter_deps : (Anchor.lib_name -> unit) -> t -> unit

val to_local_filepath : t -> path -> suffix:string -> string
val replace_local_cache : t -> path -> source_digest:Digest.t -> json -> Digest.t
val find_local_cache_opt : t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> json option

val to_filepath :
  global:(Anchor.lib_name -> path -> suffix:string -> string) ->
  t -> path -> suffix:string -> string
val replace_cache :
  global:(Anchor.lib_name -> path -> source_digest:Digest.t -> json -> Digest.t) ->
  t -> path -> source_digest:Digest.t -> json -> Digest.t
val find_cache_opt :
  global:(Anchor.lib_name -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> json option) ->
  t -> path -> source_digest:Digest.t -> cache_digest:Digest.t option -> json option