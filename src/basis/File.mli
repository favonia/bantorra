(** {1 Pure Filename Calculation} *)

val (/) : string -> string -> string
(**
   [p / q] concatenates paths [p] and [q]. The path [q] is assumed to be a relative path.
*)

val join : string list -> string
(**
   The n-ary version of {!val:(/)}
*)

(** {1 Basic I/O} *)

val writefile : string -> string -> unit
(**
   [writefile path str] writes the string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

val readfile : string -> string
(**
   [readfile path] reads the content of string [str] the file at [path] (in binary mode).
   If there was already a file at [path], it will be overwritten.
*)

(** {1 Directories} *)

val ensure_dir : string -> unit
(**
   [ensure_dir dir] effectively implements [mkdir dir] in OCaml.
*)

val protect_cwd : (string -> 'a) -> 'a
(**
   [protect_cwd f] runs [f cwd] where [cwd] is the current working directory, and restore the current
   working directory after the computation is done, even when an exception is raised.
*)

val normalize_dir : string -> string
(**
   [normalize_dir dir] uses [Sys.chdir] and [Sys.getcwd] to normalize a path. Symbolic links and special
   directories such as [.] and [..] will be resolved and the result will be an absolute path on many systems.
   The current working directory will be restored after the computation.
*)

val parent_of_normalized_dir : string -> string option
(**
   [parent_of_normalized_dir dir] calculates the parent of a normalized directory [dir]. If [dir] is already the root directory, then this function returns [None]; otherwise it returns [Some parent] where [parent] is the parent directory. The result could be wrong if [dir] was not already normalized.
*)

(** {1 Locating Files} *)

val locate_anchor : anchor:string -> string -> string * string list
(**
   [locate_anchor ~anchor dir] finds the closest regular file named [anchor] in [dir] or its ancestors in the file system tree.

   @param dir The starting directory. It will be normalized with respect to the current working director.

   @return
   (1) the first directory that holds a regular file named [anchor] on the way from [dir] to the root directory; and (2) the relative path from the returned directory to [dir].
   The exception [Not_found] is raised if such a file cannot be found.

   For example, on a typical Linux system, suppose there is no file called [anchor.txt] under directiors
   [/usr/lib/gcc/] and [/usr/lib/], but there is such a file under [/usr/].
   [locate_anchor ~anchor:"anchor.txt" "/usr/lib/gcc"] will return ["/usr", ["lib"; "gcc"]]
   and [locate_anchor ~anchor:"anchor.txt" "/usr"] will return ["/usr", []].
*)
