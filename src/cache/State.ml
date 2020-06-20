open Basis.JSON

exception IllFormed

type t = (string, float) Hashtbl.t

let version = "1.0.0"

let init () : t = Hashtbl.create 10

let access_of_json =
  function
  | filename, `Float time -> filename, time
  | _ -> raise IllFormed

let of_json : json -> t =
  function
  | `O ["version", `String v; "atime", `O logs] when v = version ->
    Hashtbl.of_seq @@ Seq.map access_of_json @@ List.to_seq logs
  | _ -> raise IllFormed

let json_of_access (filename, time) =
  filename, `Float time

let to_json s =
  let logs = List.of_seq @@ Seq.map json_of_access @@ Hashtbl.to_seq s in
  `O ["version", `String version; "atime", `O logs]

let update_atime s ~key =
  Hashtbl.replace s key @@ Unix.time ();
