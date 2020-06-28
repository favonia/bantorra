(** {1 Introduction}

    A resolver that reads the YAML user configuration at [$XDG_CONFIG_HOME/${app_name}/libraries]. Here is an example:
    {v
format: "1.0.0"
libraries:
- name: num
  version: "3"
  at: "/usr/lib/something/num34"
- name: tcp
  version: "2"
  at: "/usr/lib/something/tcp21"
    v}

    The resolver takes YAML arguments in one of the following formats:
    {v
name: "bantorra"
verson: "0.1.0"
    v}
    {v
name: "bantorra"
verson: null
    v}
    {v
name: "bantorra"
    v}
    A missing version is understood as the version [null]. Therefore, the last two specifications are identical.

    Versions are compared using structural equality. There is no smart comparison or ordering between versions. Each version is completely independent of each other; [null] only matches [null], not any string. However, one could have multiple entries as follows to dispatch on versions:
    {v
format: "1.0.0"
libraries:
- name: num
  version: "2"
  at: "/usr/lib/something/num25"
- name: num
  version: "2.5"
  at: "/usr/lib/something/num25"
- name: num
  version: "3"
  at: "/usr/lib/something/num34"
- name: num
  version: "3.4"
  at: "/usr/lib/something/num34"
- name: num
  version: null
  at: "/usr/lib/something/num34"
- name: tcp
  version: "2"
  at: "/usr/lib/something/tcp21"
- name: tcp
  version: "2.1"
  at: "/usr/lib/something/tcp21"
    v}

    {1 The Builder}
*)

val resolver : app_name:string -> config:string -> Bantorra.Resolver.t
(** [resolver ~app_name ~config] constructs a resolver that reads the user configuration. The location of the user configuration is given by {!val:BantorraBasis.Xdg.get_config_home}. All paths are normalized and turned into absolute paths with respect to the current working directory using {!val:BantorraBasis.File.normalize_dir} .
*)

val clear_cached_configs : unit -> unit
(** Configuration files are all cached to reduce I/O load, but perhaps you are bypassing this module to modify them. In that case, one should call this function to force rereading configuration files. *)

(** {1 Configuration I/O} *)

type versioned_library =
  { name : string
  ; version : string option
  }
(** The type of versioned library names. [None] corresponds to [null] and [Some ver] corresponds to explicit versions. *)

type config = {dict : (versioned_library * string) list}
(** The type of configurations as association lists. *)

val default_config : config
(** Default configuration that is empty. *)

val read_opt : app_name:string -> config:string -> config option
(** Try to read the configuration file. Note that the results are cached. See {!val:clear_cached_configs}. *)

val write : app_name:string -> config:string -> config -> unit
(** Write the configuration file. The cache will be updated upon successful writing. See {!val:clear_cached_configs}. *)
