all:
	@nasm -f elf64 -l print.lst print.asm -o print.o
	@g++ -o main.o -c main.cpp
	@g++ -no-pie -o print print.o main.o
	@./print

clean:
	@rm -rf *.o