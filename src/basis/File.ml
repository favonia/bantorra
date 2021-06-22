open StdLabels
module U = UnixLabels
open ResultMonad.Syntax

type filepath = string

let (/) p1 p2 =
  if Filename.is_relative p2 then Filename.concat p1 p2 else p2

let join = List.fold_left ~f:(/) ~init:Filename.current_dir_name

(** Write a string to a file. *)
let writefile p s =
  try
    let ch = open_out_bin p in
    Fun.protect ~finally:(fun () -> close_out_noerr ch) @@
    fun () ->
    output_string ch s;
    close_out ch;
    ret ()
  with Sys_error s -> error @@ `SystemError s

(** Read the entire file as a string. *)
let readfile p =
  try
    let ch = open_in_bin p in
    Fun.protect ~finally:(fun () -> close_in_noerr ch) @@
    fun () ->
    let s = really_input_string ch (in_channel_length ch) in
    close_in ch;
    ret s
  with Sys_error s -> error @@ `SystemError s

let getcwd = Sys.getcwd

let unsafe_chdir dir = Sys.chdir dir

let chdir dir =
  try ret @@ unsafe_chdir dir
  with Sys_error s -> error @@ `SystemError s

(** OCaml implementation of [mkdir -p] *)
let rec ensure_dir path =
  match Sys.is_directory path with
  | false ->
    Printf.ksprintf (fun msg -> error @@ `SystemError msg)
      "%s exists but is not a directory" path
  | true -> ret ()
  | exception Sys_error _ ->
    let parent = Filename.dirname path in
    let* () = ensure_dir parent in
    let rec loop () =
      try ret @@ U.mkdir ~perm:0o777 path with
      | U.Unix_error (U.EINTR, _,  _) -> loop ()
      | U.Unix_error (e, _,  _) -> error @@ `SystemError (U.error_message e)
    in
    loop ()

let protect_cwd f =
  let dir = getcwd () in
  Fun.protect ~finally:(fun () -> unsafe_chdir dir) @@ fun () -> f dir

let normalize_dir dir =
  protect_cwd @@ fun _ ->
  let+ () = chdir dir in
  getcwd ()

let parent_of_normalized_dir dir =
  let p = Filename.dirname dir in
  if p = dir then None else Some p

let file_exists p =
  try U.(stat p).st_kind = S_REG with _ -> false

let anchor_not_found fmt =
  Printf.ksprintf (fun msg -> error @@ `AnchorNotFound msg) fmt

let locate_anchor ~anchor start_dir =
  let rec find_root cwd unitpath_acc =
    if file_exists anchor then
      ret (cwd, unitpath_acc)
    else
      match parent_of_normalized_dir cwd with
      | None -> anchor_not_found "locate_anchor: no anchor found all the way up to the root"
      | Some parent ->
        unsafe_chdir parent;
        find_root parent @@ Filename.basename cwd :: unitpath_acc
  in
  protect_cwd @@ fun _ ->
  match chdir start_dir with
  | Ok () ->
    let cwd = getcwd () in
    find_root cwd []
  | Error (`SystemError msg) ->
    anchor_not_found "locate_anchor: %s" msg

let check_intercepting_anchors ~anchor root =
  function
  | [] -> false
  | part :: parts ->
    let rec loop parts =
      if file_exists anchor then
        true
      else
        match parts with
        | [] -> false
        | part :: parts ->
          match chdir (root/part) with
          | Error (`SystemError _) -> false
          | Ok () -> loop parts
    in
    protect_cwd @@ fun _ ->
    match chdir (root/part) with
    | Error (`SystemError _) -> false
    | Ok () -> loop parts

(** The scheme refers to how various directories should be determined.

    It does not correspond to the actual OS that is running. For example, the
    [Linux] scheme covers all BSD-like systems and Cygwin on Windows. *)
type scheme = MacOS | Linux | Windows

let uname_s =
  lazy begin
    Result.to_option @@
    Exec.with_system_in ~prog:"uname" ~args:["-s"] @@ fun ic ->
    String.trim @@ input_line ic
  end

let guess_scheme =
  lazy begin
    match Sys.os_type with
    | "Unix" ->
      begin
        match Lazy.force uname_s with
        | Some "Darwin" -> MacOS
        | _ -> Linux
      end
    | "Cygwin" -> Linux
    | "Win32" -> Windows
    | _ -> Linux
  end

let get_home () =
  match Lazy.force guess_scheme with
  | Windows ->
    begin
      match Sys.getenv_opt "USERPROFILE" with
      | Some userprofile -> Some userprofile
      | None ->
        match Sys.getenv_opt "HOMEPATH" with
        | None -> None
        | Some homepath ->
          let drive = Option.value ~default:"" @@ Sys.getenv_opt "HOMEDRIVE" in
          Some (drive/homepath)
    end
  | Linux | MacOS ->
    match Sys.getenv_opt "HOME" with
    | Some home -> Some home
    | None ->
      let rec loop () =
        try
          Some Unix.(getpwuid @@ getuid ()).pw_dir
        with
        | Unix.Unix_error (Unix.EINTR, _, _) -> loop ()
        | Unix.Unix_error _ -> None
      in
      loop ()

let expand_home =
  (* ["~/"] in the most portable way *)
  let home_prefix = "~" ^ Filename.dir_sep in
  fun p ->
    match get_home () with
    | None -> p
    | Some home ->
      if String.(length p >= length home_prefix) &&
         String.(equal (sub ~pos:0 ~len:(length home_prefix) p) home_prefix)
      then
        home / String.sub ~pos:1 ~len:(String.length p - 1) p
      else
        p

(* XXX I did not test the following code on different platforms. *)
let get_xdg_config_home ?(as_linux=false) ~app_name =
  match Sys.getenv_opt "XDG_CONFIG_HOME" with
  | Some dir -> dir/app_name
  | None ->
    match Lazy.force guess_scheme, as_linux with
    | Linux, _ | _, true ->
      Sys.getenv "HOME"/".config"/app_name
    | MacOS, false ->
      Sys.getenv "HOME"/"Library"/"Application Support"/app_name
    | Windows, false ->
      Sys.getenv "APPDATA"/app_name/"config"

(* XXX I did not test the following code on different platforms. *)
let get_xdg_cache_home ?(as_linux=false) ~app_name =
  match Sys.getenv_opt "XDG_CACHE_HOME" with
  | Some dir -> dir/app_name
  | None ->
    match Lazy.force guess_scheme, as_linux with
    | Linux, _ | _, true ->
      Sys.getenv "HOME"/".cache"/app_name
    | MacOS, false ->
      Sys.getenv "HOME"/"Library"/"Caches"/app_name
    | Windows, false ->
      Sys.getenv "LOCALAPPDATA"/app_name/"cache"
