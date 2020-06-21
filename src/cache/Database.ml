open Basis
open Basis.File

let state_file = "state"
let data_subdir = "data"

type t =
  { root : string
  ; state : State.t
  }

let read_state ~root =
  try State.of_yaml @@ YamlIO.read_gzip (root/state_file) with _ -> State.init ()

let init ~root =
  ensure_dir (root/data_subdir);
  {root; state = read_state ~root}

let save {root; state} =
  YamlIO.write_gzip (root/state_file) @@ State.to_yaml state

let digest_of_item ~key:_ ~value =
  Digest.string @@ YamlIO.to_gzip value

let replace_item {root; state} ~key ~value =
  let key = YamlIO.digest_of_value key
  and value = YamlIO.to_gzip value in
  writefile_noerr (root/data_subdir/key) value;
  State.update_atime state ~key;
  Digest.string value

let check_digest d s =
  match d with
  | None -> ()
  | Some d -> if Digest.string s <> d then failwith "Digest not matched"

let find_item_opt {root; state} ~key ~digest =
  let key = YamlIO.digest_of_value key in
  try
    let value = readfile @@ root/data_subdir/key in
    check_digest digest value;
    let value = YamlIO.of_gzip value in
    State.update_atime state ~key;
    Some value
  with
  | _ -> None
