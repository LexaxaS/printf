all: asm cuse link run

asm:
	@nasm -f elf64 -g printf.s -o myprintf.o

cuse:
	@gcc -g -c c_printf.c -o c_printf.o

link:
	@gcc -no-pie myprintf.o c_printf.o -o main

run:
	@./main