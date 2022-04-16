test: test.o
	ld test.o -o test -lc -e main -dynamic-linker /lib/ld-linux-x86-64.so.2

test.o: test.asm
	nasm -f elf64 test.asm

clean:
	rm test.o test
