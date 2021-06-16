(** {1 Types} *)

type value = Ezjsonm.value
(** The type suitable for marshalling. This is the universal type to exchange information
    within the framework. *)

exception IllFormed
(** The exception indicating errors during encoding, decoding, or I/O. *)

(** {1 Human-Readable Serialization} *)

(** These are functions to retrieve the data of type [value] in the JSON format.
    They are suitable for reading configuration files created by users. *)

val of_json : string -> value
(** A function that deserializes a value. *)

val read_json : string -> value
(** [read_json path v] reads and deserializes the content of the file at [path]. *)

(** {2 Unsafe API} *)

val unsafe_to_json : value -> string
(** A function that serializes a value. This function does not quote strings properly due to a bug in the [json] package. *)

val unsafe_write_json : string -> value -> unit
(** [unsafe_write_json path v] writes the serialization of [v] into the file at [path]. This function does not quote strings properly due to a bug in the [json] package. *)

(** {1 Helper Functions} *)

val of_string : string -> value
(** Embedding a string into a [value]. *)

val to_string : value -> string
(** Projecting a string out of a [value]. *)

val of_ostring : string option -> value
(** Embedding an optional string into a [value]. *)

val to_ostring : value -> string option
(** Projecting an optional string out of a [value]. *)

val of_list : ('a -> value) -> 'a list -> value
(** Embedding a list into a [value]. *)

val to_list : (value -> 'a) -> value -> 'a list
(** Projecting a list out of a [value]. *)

val of_float : float -> value
(** Embedding a float into a [value]. *)

val to_float : value -> float
(** Projecting a float out of a [value]. *)

val dump : value -> string
(** A quick, dirty converter to turn a [value] into a string for ugly-printing. *)
