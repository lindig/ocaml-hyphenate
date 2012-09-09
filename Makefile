
#
# Makefile
#

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

%.ml:		hyphen.lp
		$(LP) tangle -f cpp $@ $< > $@

%.mli:		hyphen.lp
		$(LP) tangle -f cpp $@ $< > $@

%.mll:		hyphen.lp
		$(LP) tangle -f cpp $@ $< > $@

README.md: 	hyphen.lp
		$(LP) weave $< > $@
