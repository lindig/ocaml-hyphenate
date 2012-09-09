#
# Makefile
#
# Lipsum is available from https://github.com/lindig/lipsum. Try
#
#   make lipsum
#
# to build it and edit the definition of LP below to use it.

LP		= ./lipsum/lipsum
LP 		= lipsum
OCB 		= ocamlbuild

SRC 		=  hyphenate.mli hyphenate.ml 
SRC		+= hyphenate_reader.mli hyphenate_reader.mll
SRC		+= demo.ml

LANG		=  hyphenate_us.mli hyphenate_us.ml

DOC		= README.md

all: 		$(SRC) $(DOC)
		$(OCB) demo.native 

debug:		$(SRC)
		$(OCB) demo.d.byte

clean: 		
		$(OCB) -clean
		rm -f $(SRC) $(DOC)
		# rm -f lipsum

%.ml:		hyphen.lp
		$(LP) tangle -f cpp $@ $< > $@

%.mli:		hyphen.lp
		$(LP) tangle -f cpp $@ $< > $@

%.mll:		hyphen.lp
		$(LP) tangle -f cpp $@ $< > $@

README.md: 	hyphen.lp
		$(LP) weave $< > $@

lipsum:
		git clone https://github.com/lindig/lipsum
		cd lipsum && make

