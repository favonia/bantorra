(** {1 Types} *)

type unitpath = Anchor.unitpath
(** The type of unit paths. *)

type t
(** The type of libraries. *)

(** {1 Initialization} *)

val init : anchor:string -> root:BantorraBasis.File.filepath -> t
(** Initite a library rooted at [root] where the name of the anchor file is [anchor]. *)

val locate_anchor_from_file : anchor:string -> suffix:string -> BantorraBasis.File.filepath -> BantorraBasis.File.filepath * unitpath
(** See {!val:Manager.locate_anchor_from_file}. *)

val locate_anchor_from_dir : anchor:string -> BantorraBasis.File.filepath -> BantorraBasis.File.filepath * unitpath
(** See {!val:Manager.locate_anchor_from_dir}. *)

val locate_anchor_from_cwd : anchor:string -> BantorraBasis.File.filepath * unitpath
(** See {!val:Manager.locate_anchor_from_cwd}. *)

(** {1 Accessor} *)

val iter_deps : (Anchor.lib_ref -> unit) -> t -> unit
(** Iterate over all dependencies listed in the anchor. *)

(** {1 Hook for Library Managers} *)

(** The following API is for a library manager to chain all the libraries together.
    Please use the high-level API in {!module:Manager} instead. *)

val to_unitpath :
  global:(current_root:BantorraBasis.File.filepath -> Anchor.lib_ref -> unitpath -> t * unitpath) ->
  t -> unitpath -> t * unitpath
(** [to_unitpath ~global lib unitpath] resolves [unitpath] and returns the eventual library where the unit belongs and the local unit path pointing to the unit.

    @param global The global resolver for unit paths pointing to other libraries.
*)

val to_filepath :
  global:(current_root:BantorraBasis.File.filepath -> Anchor.lib_ref -> unitpath -> suffix:string -> t * BantorraBasis.File.filepath) ->
  t -> unitpath -> suffix:string -> t * BantorraBasis.File.filepath
(** [to_filepath ~global lib unitpath ~suffix] resolves [unitpath] and returns the eventual library where the unit belongs and the underlying file path of the unit. It is similar to {!val:to_unitpath} but returns a file path instead of a unit path.

    @param global The global resolver for unit paths pointing to other libraries.
    @param suffix The suffix shared by all the units in the file system.
*)
