as -g -o printf.o $1 &&
	ld --entry main -o out printf.o &&
	./out
