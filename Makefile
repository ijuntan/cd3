run_all: parser
	./parser $(filename).st
	./javaa $(filename).jasm
	java $(filename)     

run_parser: parser

parser: lex.yy.c y.tab.c symbols.c symbols.h code.h code.c
	gcc y.tab.c lex.yy.c symbols.c code.c -lfl -ly -o parser 
 
lex.yy.c: p.l
	flex p.l

y.tab.c: p.y
	yacc -d -v p.y

clean:
	rm -f lex.yy.c y.tab.c y.tab.h