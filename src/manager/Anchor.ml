open BantorraBasis
open ResultMonad.Syntax

let version = "1.0.0"

type unitpath = string list
type router_argument = Router.router_argument
type lib_ref =
  { router : string
  ; router_argument : router_argument
  }

type t =
  { routes : (unitpath, lib_ref) Hashtbl.t
  ; cache : (unitpath, (lib_ref * unitpath) option) Hashtbl.t
  }

module M =
struct
  let to_path = Marshal.(to_list to_string)

  let to_route =
    function
    | `O ms ->
      Marshal.parse_object_fields ~required:["mount_point"; "router"] ~optional:["router_argument"] ms >>=
      begin function
        | ["mount_point", mount_point; "router", router], ["router_argument", router_argument] ->
          let+ router = Marshal.to_string router
          and+ prefix = to_path mount_point
          in
          prefix, {router; router_argument}
        | _ -> assert false
      end
    | v -> Marshal.invalid_arg ~f:"Anchor.deserialize" v "not an object"
end

let deserialize : Marshal.value -> (t, _) result =
  let cache = Hashtbl.create 10 in
  function
  | `Null ->
    ret {routes = Hashtbl.create 0; cache}
  | `O ms as v ->
    Marshal.parse_object_fields ~required:["format"] ~optional:["routes"] ms >>=
    begin function
      | ["format", format], ["routes", routes] ->
        let* format = Marshal.to_string format in
        if format <> version then
          Marshal.invalid_arg ~f:"Anchor.deserialize" v "unsupported version %s" format
        else begin
          let* routes = Option.value ~default:[] <$> Marshal.to_olist M.to_route routes in
          match Util.Hashtbl.of_unique_seq @@ List.to_seq routes with
          | Error (`DuplicateKeys k) -> error @@
            `FormatError (Printf.sprintf "multiple libs mounted at %s" @@ Util.string_of_unitpath k)
          | Ok routes -> ret {routes; cache}
        end
      | _ -> assert false
    end
  | v -> Marshal.invalid_arg ~f:"Anchor:deserialize" v "not an object"

let read anchor = Marshal.read_json anchor >>= deserialize

let iter_routes f {routes; _} =
  ResultMonad.iter_seq (fun (_, lib_name) -> f lib_name) @@ Hashtbl.to_seq routes

let match_prefix unitpath prefix k =
  let rec loop unitpath prefix acc =
    match unitpath, prefix with
    | _, [] -> Some (acc, k unitpath)
    | [], _ -> None
    | (id :: unitpath), (id' :: prefix) ->
      if String.equal id id' then loop unitpath prefix (acc+1) else None
  in loop unitpath prefix 0

let match_route unitpath (mount_point, lib) =
  match_prefix mount_point unitpath @@ fun unitpath -> lib, unitpath

let is_local {routes; _} unitpath =
  let matched = Seq.filter_map (match_route unitpath) @@ Hashtbl.to_seq routes in
  match matched () with
  | Seq.Cons _ -> false
  | _ -> true

let max_match x y =
  match x, y with
  | Some (n0, _), (n1, _) when (n0 : int) >= n1 -> x
  | _ -> Some y

let dispatch_path_without_cache {routes; _} unitpath =
  let matched = Seq.filter_map (match_route unitpath) @@ Hashtbl.to_seq routes in
  Option.map snd @@ Seq.fold_left max_match None matched

let dispatch_path anchor unitpath =
  match Hashtbl.find_opt anchor.cache unitpath with
  | Some ref -> ref
  | None ->
    let ref = dispatch_path_without_cache anchor unitpath in
    Hashtbl.replace anchor.cache unitpath ref;
    ref