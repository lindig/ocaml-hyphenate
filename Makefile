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

SRC =   hyphenate.mli 
SRC +=	hyphenate.ml 
SRC +=	hyphenate_reader.mli 
SRC +=	hyphenate_reader.mll
SRC +=	demo.ml

LANG		=  hyphenate_us.mli hyphenate_us.ml

DOC		= README.md

all: 		$(SRC) $(DOC)
		$(OCB) demo.native 

debug:		$(SRC)
		$(OCB) demo.d.byte

profile:	$(SRC)
		$(OCB) demo.p.native
clean: 		
		$(OCB) -clean
		rm -f $(SRC) $(DOC)
		rm -f gmon.out
		# rm -f lipsum

test:		performance

performance:	all
		echo "expect about 3.5 seconds real time"
		time ./demo.native -f /usr/share/dict/words | wc

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
		$(MAKE) -C lipsum

