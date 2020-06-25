open BantorraBasis
open BantorraBasis.File
module S = BantorraCache.Store

type unitpath = Anchor.unitpath

type t =
  { root : string
  ; anchor : Anchor.t
  ; cache : S.t
  }

let default_cache_subdir = "_cache"

let init ~anchor ~root =
  let anchor = Anchor.read @@ root / anchor
  and cache = S.init ~root:(root / default_cache_subdir) in
  {root; anchor; cache}

let save_state {cache; _} =
  S.save_state cache

let iter_deps f {anchor; _} = Anchor.iter_deps f anchor

let dispatch_path local ~global lib path =
  match Anchor.dispatch_path lib.anchor path with
  | None -> local lib path
  | Some (lib_name, path) -> global ~cur_root:lib.root lib_name path

(** @param suffix The suffix should include the dot. *)
let to_local_filepath {root; _} path ~suffix =
  match path with
  | [] -> invalid_arg "to_rel_filepath: empty unit path"
  | path -> File.join (root :: path) ^ suffix

(** Generate the JSON [key] from immediately available metadata. *)
let make_local_key path ~source_digest : Marshal.value =
  `O [ "path", `A (List.map (fun s -> `String s) path)
     ; "source_digest", `String source_digest
     ]

let replace_local_cache {cache; _} path ~source_digest value =
  let key = make_local_key path ~source_digest in
  S.replace_item cache ~key ~value

let find_local_cache_opt {cache; _} path ~source_digest ~cache_digest =
  let key = make_local_key path ~source_digest in
  S.find_item_opt cache ~key ~digest:cache_digest

(** @param suffix The suffix should include the dot. *)
let to_filepath = dispatch_path to_local_filepath
let replace_cache = dispatch_path replace_local_cache
let find_cache_opt = dispatch_path find_local_cache_opt
