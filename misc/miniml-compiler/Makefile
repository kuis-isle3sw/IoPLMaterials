PROG=minimlc

default: main

main: main.native

%.native: 
	ocamlbuild -use-ocamlfind -use-menhir $@
	mv $@ $(PROG)

.PHONY: default

clean:
	ocamlbuild -clean
