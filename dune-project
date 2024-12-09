(lang dune 3.17)

(using menhir 2.1)

(implicit_transitive_deps false)

(license CC-BY-NC-ND-4.0)

(authors "Kohei Suenaga <ksuenaga@gmail.com>")

(maintainers "Kohei Suenaga <ksuenaga@gmail.com>")

(source
 (github kuis-isle3sw/IoPLMaterials))

(generate_opam_files true)

(package
 (name miniml-compiler)
 (synopsis "Dummy package context for MiniML compiler")
 (depends
  ocaml
  menhir
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))))

(package
 (name miniml-interpreter)
 (synopsis "Dummy package context for MiniML interpreter")
 (depends
  ocaml
  menhir
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))))

(package
 (name tutorial)
 (synopsis "Dummy package context for OCaml tutorial")
 (depends
  ocaml
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))))
