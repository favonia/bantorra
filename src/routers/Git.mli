(** A router that downloads git repositories. *)

open BantorraBasis

(** The git resolver takes a URL that the [git] tool can understand, clones the repository and returns the library root within the local copy.

    The resolver takes a JSON argument in one of the following formats:
    {v
{
    "url": "git@github.com:favonia/bantorra.git",
    "ref": "main",
    "path": "src/library"
}
    v}
    {v
{
    "url": "git@github.com:favonia/bantorra.git",
    "ref": "main"
}
    v}
    {v
{
    "url": "git@github.com:favonia/bantorra.git",
    "path": "src/library"
}
    v}
    {v
{
    "url": "git@github.com:favonia/bantorra.git"
}
    v}
    The [ref] field can be a commit ID, a branch name, a tag name, or anything accepted by [git fetch]. The only restriction is that [ref] should not contain a non-empty branch destination [<dst>] in the git ref specification as in the documentation of [git fetch]. (The older [git] before year 2015 would not accept commit IDs, but please upgrade it already.) The [path] field is the relative path pointing to the root of the library. If the [path] field is missing, then the tool assumes the library is at the root of the repository. If the [ref] field is missing, then ["HEAD"] is used, which should point to the tip of the default branch in the remote repository.

    Different URLs pointing to the "same" git repository are treated as different libraries. Therefore, [git@github.com:RedPRL/bantorra.git] and [https://github.com/RedPRL/bantorra.git] are treated as two different git repositories. The resolver cannot identify a remote git repository with any local copy not managed by the resolver, either. A proper solution to this problem is a different resolver mapping global package names to repositories, such as the OPAM package index for the OCaml language.

    Given the same URL, the commit IDs in use must be identical during the program execution. One can use different branch names or tag names, but they all need to point to the same commit ID. The resolution would fail if there is an attempt to use different commits of the same repository. Otherwise, the semantics of importing would be broken. As a result, it is a good idea to use stable tags in larger developments, unless the latest commit is absolutely needed. One common case would be two libraries in the same repository depending on each other, but then one should local, relative references such as {e waypoints} implemented by {!module:BantorraRouters.Waypoint}.

    {1 The Builder}
*)

val router : ?eager_resolution:bool -> crate_root:File.filepath -> (Bantorra.Router.t, [> `InvalidRouter of string ]) result
(** [router ~crate_root] downloads git repositories, when requested, into the directory [crate_root] and resolves the URL into a path pointing to a local copy of the library. The resolver assumes the directory [crate_root] already exists and it has total control over the directory during the program execution.

    @param eager_resolution Whether full resolution is performed to check the validity of arguments. If the value is [true], the resolver will immediately download the library when it receives a URL. If the value is [false], the resolver will only check whether the argument is well-formed JSON. The default value is [false].
*)
