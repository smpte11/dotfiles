# OCaml / opam integration for nushell.

# Load the opam environment into the current shell — the nushell equivalent of
# `eval $(opam env)`. opam has no native nushell output, so we parse its
# powershell output (the easiest to parse) into a record and load it.
# See https://stackoverflow.com/questions/79760891/how-do-i-use-eval-opam-env-with-nushell
export def --env opam-env [] {
    opam env --shell=powershell
    | parse "$env:{key} = '{val}'"
    | transpose -rd
    | load-env
}
