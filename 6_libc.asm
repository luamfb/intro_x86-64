; Copyright 2018-2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.
;

; (6) libc.asm: using C library functions
;
; Here we'll revisit our old friends main() and printf().
; Since C files turn into assembly at some point, it makes sense to expect it
; to be possible to call C library functions in assembly. But to do so,
; we must link our object file against the C library, and a few things must
; change for us to do that.
;
; Note: you'll need to use the -no-pie option to link this file with gcc.
;

; again, the 'global' directive tells nasm to export a symbol to the linker.
; When we were using _start, this just saved us from a warning when linking,
; because the linker is generally smart enough to find where _start is.
; Now, however, if this directive isn't used, the linker will complain that
; the C library has an undefined reference to main, and will fail. (*)
; (See below for why we're using main instead of _start.)
;
global main

; these are the symbols we'll be using from the standard library.
; The linker doesn't need this, but nasm does, so it won't complain about
; undefined symbols. (*)
;
extern printf
extern atoi

section .data
	; note how we add the null byte at the end: this string will be used by
	; printf(), so we need to do that.
	;
	fmt: db '%d + %d = %d',0xA,0x0
	; also, because the string is null terminated, we don't need to
	; keep track of its size.

	usageMsg: db 'usage: %s first_number second_number',0xA,0x0

; this simple program adds two numbers given as command-line arguments
; and prints the result.
;
section .text
;
; Note how we use main() here instead of _start.
; The C language defines main() as the first function to be called, but other
; than that - and unlike _start - main() is a normal function, which needs to be
; called with arguments, and which returns. So, who calls main()?
; And where is _start now?
; The answer to both of those is: the C library.
; Even if a C program does not use anything from the C library, it still must be
; linked against it because that library is what provides a _start definition,
; which will make all necessary preparations and call main().
;
; So if we were to use _start here, the linker could complain twice: first
; because it can't find the definition of the 'main' symbol that the C library
; references, second because there's two definitions of _start. (*)
;
main:
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15

	; main has the prototype
	;	int main(int argc, char **argv);
	; Those arguments are where you would expect them: argc, being the first
	; parameter, is in rdi, and argv, the second one, is in rsi.
	; We store those in callee-saved registers, as usual.
	;
	mov r12, rdi ; argc
	mov r13, rsi ; argv

	; allocate space for two ints (4 bytes each)
	sub rsp, 8

	; Since argv[0] is the program name, the numbers we want to add were
	; passed as strings in argv[1] and argv[2].
	;
	; make sure that argc == 3
	cmp r12, 3
	jne .fail

	; convert argv[1] and argv[2] to integers
	mov rdi, qword [r13 + 8] ; argv[1]
	call atoi
	mov dword [rsp], eax

	mov rdi, qword [r13 + 16] ; argv[2]
	call atoi
	mov dword [rsp+4], eax

	; add the numbers.
	; ADD won't take two memory locations as arguments, so we need to load
	; one of them into a register.
	mov ecx, dword [rsp]
	add ecx, dword [rsp+4]

	; finally, print the value!
	; we want to call printf as:
	;	printf(fmt, num1, num2, sum);
	; (where num1 and num2 are the ints corresponding converted from argv)
	mov rdi, fmt
	mov esi, [rsp] ; the argument is 4 bytes, so we use esi instead of rsi
	mov edx, [rsp+4]
	; the sum of the two numbers is already in ecx

	; this is all it takes to call printf(). Calling a library function
	; is no different than calling any other function: the linker figures
	; everything out for you.
	;
	call printf

	xor rax, rax ; exit status
	jmp .end
.fail:
	mov rdi, usageMsg
	mov rsi, [r13] ; argv[0]
	call printf
	mov rax, 1 ; exit status
.end:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	mov rsp, rbp
	pop rbp
	ret

; Exercises
;
; === St Thomas' Wisdom ===
; Verify all claims marked with (*).
;
; === Reverse engineering ===
; Feed a C compiler the following code:
;
;	struct pair {
;		int a;
;		int b;
;	};
;
;	int main(int argc, char **argv)
;	{
;		struct pair p = {2, 5};
;		/* do something with p */
;		return 0;
;	}
;
; And see the resulting program's instructions. Where is p stored?
; Now, change the main function to:
;
;	int main(int argc, char **argv)
;	{
;		struct pair *p = malloc(sizeof(struct pair));
;		p->a = 2;
;		p->b = 5;
;		/* do something with p */
;		free(p);
;		return 0;
;	}
;
; Where is p stored now?
;
; === Your Turn ===
;	- Write a program that takes any number of command line arguments,
;	and prints their characters interleaved: the first character of each
;	argument must be printed in sequence, then the second, and so on.
;	For simplicity's sake, your program can refuse arguments of different
;	lengths.
;
;	- Write a program that reads a sequence of integers from standard input
;	and sorts it using the qsort() function.
;
; === Fly Higher ===
; We've shown how to use the standard C library with assembly, but you can use
; any C library in a similar fashion (as long as you link it against the final
; executable.) Write a simple assembly program that uses some library you're
; familiar with.
; If you're out of ideas, here are a few, with the suggested libraries in
; parenthesis:
;	- Create a blank GUI window, then destroy it after N seconds (SDL, XCB)
;	- Play a WAV file, or a single note with fixed duration (SDL, openAL?)
;	- Encrypt user input with AES, or compute its MD5 hash (openSSL)
;	- Fetch an HTML file from an HTTP URL (libcurl)
;
; (Note: we haven't yet explained how to deal with floating point numbers.
; If you believe you'll need to use them, feel free to skip to the next file
; and come back later.)

; vim: set ft=nasm:
