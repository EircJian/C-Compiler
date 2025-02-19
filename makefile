#codegen.o: main.c asm.S
#	riscv64-unknown-elf-gcc -o codegen.o main.c asm.S
#asm.S: parser
#	./parser
parser: lex.yy.c y.tab.c
	gcc -o parser lex.yy.c y.tab.c -lfl
y.tab.c: parser.y
	byacc -d parser.y
lex.yy.c: scanner.l
	flex scanner.l
