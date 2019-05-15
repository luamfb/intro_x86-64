// Copyright 2019 Luana Carmo M de F Barbosa
//
// This file is licensed under the CC-BY-SA 2.0 license.
// See LICENSE for details.
//
// main.c: C code calling assembly code.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define BUFFER_SIZE 1024

// declare the functions that were defined in the other file.
// We use integer types with explicit sizes, to be on the safe side.
//
extern uint64_t factorial(uint64_t n);
extern uint64_t uint2str(uint64_t n, uint8_t *buf, uint64_t bufsize);

int main(int argc, char **argv)
{
	if (argc != 2) {
		fprintf(stderr, "usage: %s number\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	int num = atoi(argv[1]);

	// the function call works normally. Only an extra cast is needed
	uint64_t fact = factorial((uint64_t) num);
	//printf("%d\n", fact);

	uint8_t buf[BUFFER_SIZE];
	// note that buf is passed to uint2str as a pointer, which the assembly
	// code will access through the addressing mode.
	//
	uint64_t last_index = uint2str(fact, buf, BUFFER_SIZE);
	if (last_index >= BUFFER_SIZE) {
		fprintf(stderr, "result is too large to fit in buffer\n");
		exit(EXIT_FAILURE);
	}
	// the resulting string is not null terminated: add it manually.
	buf[last_index] = '\0';

	// no newline because buf already has one
	printf("%d! = %s", num, buf);

	return 0;
}
