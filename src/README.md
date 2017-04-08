# MiniML Interpreter

「プログラミング言語処理系」と「計算機科学実験及演習３」の履修者へ：この README は課題を行うにあたって重要な情報を含んでいるので，ちゃんと全部読むこと．

This directory contains the source files for MiniML interpreter, an
interpreter of a subset of OCaml used in the class "Implementation of
Programming Languages" provided by the Department of Engineering,
Kyoto University.

## Required software/library

You need OCaml (http://ocaml.org/) and a parser generator Menhir
(http://gallium.inria.fr/~fpottier/menhir/) to build this interpreter.

We strongly recommend installing opam (https://opam.ocaml.org/), the
standard package manager for OCaml as of 2017.  You can install many
useful libraries with opam.
- Read https://opam.ocaml.org/doc/Install.html for installing opam to
  your computer.  (The computer system at the Keisanki course already
  has opam.)
- (You need to do this step only once.)  Type `opam init` first.  To
  install menhir, type `opam install menhir`.
- To update the package list, type `opam update`.
- To upgrade all the packages installed to your system, type `opam
  upgrade`.
- For more detailed usage, see https://opam.ocaml.org/doc/Usage.html

## Building and invoking MiniML interpreter

Software written in OCaml 
- Type `make` to build.
- Type `./miniml` to invoke the interpreter.

(This paragraph can be skipped safely.)  By default, `make` generates
bytecode interpreted by `ocamlrun`.  Type `make nc` if you want native
code.  Type `make dc` if you want to debug your code with
`ocamldebug`.

## Files

This directory contains the following files.

- `main.ml`: The entry point of the entire interpreter.
- `syntax.ml`: Definition of the type for MiniML abstract syntax trees.
- `eval.ml`: The functions that evaluate MiniML expressions/declarations.
- `parser.mly`: The definition of the MiniML parser.
- `lexer.mll`: The definition of the MiniML lexer.
- `environment.mli`: The interface of the ADT (abstract data type) for
  an environment -- an important data structure often used in
  interpreters and compilers.
- `environment.ml`: The implementation of the ADT for an environment.
- `mySet.mli`: The interface of the ADT for a set.
- `mySet.ml`: The implementation of the ADT for a set.
- `typing.ml`: The implementation of MiniML type inference (to be
  implemented by students.)
- `Makefile`: Makefile interpreted by `make`.
- `OCamlMakefile`: A skelton of a makefile for an OCaml project
  provided by ocaml-makefile
  (http://mmottl.github.io/ocaml-makefile/).

After typing `make`, the OCaml compiler generates many intermediate
files.  Important files among them are following.
- `parser.automaton`: Description of the LR(1) automaton generated
  from `parser.mly`.  If you encounter a conflict(s) after customizing
  the parser, read this file carefully (and think how you should
  correct your parser).
