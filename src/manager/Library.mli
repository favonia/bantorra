open BantorraBasis

(** {1 Types} *)

type unitpath = Anchor.unitpath
(** The type of unit paths. *)

type t
(** The type of libraries. *)

(** {1 Initialization} *)

val load_from_root : find_cache:(string -> t option) -> anchor:string -> File.filepath ->
  (t, [> `InvalidLibrary of string ]) result

val load_from_dir : find_cache:(string -> t option) -> anchor:string -> File.filepath ->
  (t * unitpath option, [> `InvalidLibrary of string ]) result

val load_from_unit : find_cache:(string -> t option) -> anchor:string -> suffix:string -> File.filepath ->
  (t * unitpath option, [> `InvalidLibrary of string ]) result

(** {1 Accessor} *)

val root : t -> File.filepath

val iter_routes :
  (router:string -> router_argument:Marshal.value -> (unit, 'e) result) ->
  t -> (unit, 'e) result

(** {1 Hook for Library Managers} *)

(** The following API is for a library manager to chain all the libraries together.
    Please use the high-level API in {!module:Manager} instead. *)

val resolve :
  global:(starting_dir:File.filepath ->
          router:string ->
          router_argument:Marshal.value ->
          unitpath ->
          suffix:string ->
          (t * unitpath * File.filepath, [> `UnitNotFound of string] as 'e) result) ->
  t -> unitpath -> suffix:string -> (t * unitpath * File.filepath, 'e) result
(** [to_unitpath ~global lib unitpath] resolves [unitpath] and returns the eventual library where the unit belongs and the local unit path pointing to the unit.

    @param global The global resolver for unit paths pointing to other libraries.
*)
