all: test_datastructures test_stdlib

test_datastructures: test_datastructures.o
	ld test_datastructures.o -o test_datastructures -lc -e main -dynamic-linker /lib/ld-linux-x86-64.so.2
	rm test_datastructures.o

test_stdlib: test_stdlib.o
	ld -m elf_x86_64 test_stdlib.o -o test_stdlib
	rm test_stdlib.o

test_datastructures.o: test_datastructures.asm
	nasm -f elf64 test_datastructures.asm

test_stdlib.o: test_stdlib.asm
	nasm -f elf64 -F dwarf -g test_stdlib.asm

clean:
	rm test_stdlib test_datastructures
