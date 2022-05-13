(lang dune 3.1)

(using menhir 2.1)

(generate_opam_files true)

(license CC-BY-NC-ND-4.0)

(authors "Kohei Suenaga <ksuenaga@gmail.com>")

(maintainers "Kohei Suenaga <ksuenaga@gmail.com>")

(source
 (github kuis-isle3sw/IoPLMaterials))

(package
 (name miniml-compiler)
 (synopsis "Dummy package context for MiniML compiler")
 (depends ocaml menhir))

(package
 (name miniml-interpreter)
 (synopsis "Dummy package context for MiniML interpreter")
 (depends ocaml menhir))

(package
 (name tutorial)
 (synopsis "Dummy package context for OCaml tutorial")
 (depends ocaml))
