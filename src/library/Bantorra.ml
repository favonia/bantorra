(**
   A Bantorra library manager in the Bantorra framework maintains a tree of units that can be accessed via unit paths from the root. The framework maps each unit path to the underlying file path through a flexible resolution process that supports many existing mechanisms found in other library management systems. It also supports caching of compiled results.

   In the simplest case, there is a one-to-one correspondence between units and files under a directory: the unit path [a.b.c] corresponds to the file [a/b/c.suffix] where [suffix] is specified by the application. The root directory is marked by the existence of a special file with a name specified by the application. For example, the existence of the [dune] file means there is an OCaml library in the eyes of the [dune] building tool. These files are called {e anchors} in the Bantorra framework, each marking the root of a collection of units that forms a {e library}.

   To access the units outside the current library, an anchor may {e mount} a library in the tree, in a way similar to how partitions are mounted in POSIX-compliant systems. Here is a sample anchor file:
   {v
format: "1.0.0"
deps:
  - mount_point: [lib, num]
    resolver: builtin
    res_args: number
    v}
   The above anchor file mounts the library [number] at [lib.num] via the [builtin] resolver. With this, the unit path [lib.num.types], for example, will be understood as the unit path [types] within the library [number]. The [builtin] resolver here is responsible for locating the root of this [number] library. The resolution is recursive because the depended library may depend on yet another library.

   The application can specify an arbitrary mapping from labels such as [builtin] to resolvers, possibly including new ones created for the application. There are a few basic resolvers in {{:../BantorraResolvers/index.html}BantorraResolvers}.
*)

(** {1 Modules} *)

module Manager = Manager
(** Library managers. *)

module Resolver = Resolver
(** Library resolvers. *)