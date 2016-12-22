all: test.native m2m.native

test.native: test.ml
	ocamlbuild -use-ocamlfind test.native

m2m.native: m2m.ml
	ocamlbuild -use-ocamlfind m2m.native

clean:
	ocamlbuild -clean
