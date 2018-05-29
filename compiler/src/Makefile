default: main

main: main.native

%.native: 
	ocamlbuild -use-ocamlfind -use-menhir $@
	mv $@ $*

.PHONY: default

clean:
	ocamlbuild -clean
