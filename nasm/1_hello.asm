; Copyright 2018 Luana Carmo M de F Barbosa
;
; Permission is hereby granted, free of charge, to any person obtaining
; a copy of this software and associated documentation files
; (the "Software"), to deal in the Software without restriction,
; including without limitation the rights to use, copy, modify, merge,
; publish, distribute, sublicense, and/or sell copies of the Software,
; and to permit persons to whom the Software is furnished to do so,
; subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included
; in all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;

; (1) hello.s: hello world
; It's assumed you've read code 0 first.
;

global _start

section .data
	; The directive 'db' means 'declare bytes':
	; while the label 'str'
	; stores the address of the beginning of that string.
	; Note the string declared is not null terminated, so we need
	; to keep track of its size, which we do next (with STRSIZE).
	; Also note that 0xA is the ascii value for Line Feed (newline).
	;
	str: db "hello, world", 0xA

	; The lone '$' is the address the assembler is currently at,
	; so by subtracting it from 'str' we get the number of bytes in
	; the declared string (and that works even if we were to change
	; the string.)
	;
	STRSIZE: equ $ - str

	; stdout's file descriptor.
	; (a file descriptor is a number used in Unix to refer to an
	; open file. Special files like stdout are always open,
	; and have fixed file descriptors; stdout's file descriptor is 1.)
	;
	STDOUT: equ 1

section .text
_start:
	; If you want to do anything actually useful in assembly,
	; you'll need the OS's blessing through a system call.
	; That's also the case for I/O: in order to write something
	; to stdout, we'll need to use the 'write' system call.
	; You can see the full list of system calls with
	;	$ man 2 syscalls
	; And you can see more info about the syscall <foo> with
	;	$ man 2 <foo>
	; From write's manpage:
	;	ssize_t write(int fd, const void *buf, size_t count);
	;	[...]
	;	write() writes up to count bytes from the buffer starting
	;	at buf to the file referred to by the file descriptor fd.
	;
	; All these mov instructions place the system call arguments
	; where they should be (more on this later).
	;

	mov rax, 1 ; __NR_write (more on this later)
	mov rdi, STDOUT
	mov rsi, str 
	mov rdx, STRSIZE

	; In 64-bit mode, a system call is done with a dedicated 'syscall'
	; instruction. In 32-bit, we'd need to use 'int 0x80'
	; ('int' is the instruction for interrupt, 0x80 is the Linux
	; kernel's interruption handler).
	; The kernel knows which system call we want seeing the number
	; in rax: it must be the number matching the system call.
	; In 64 bits, those are defined in
	;	/usr/include/asm/unistd_64.h
	; as macros __NR_<foo>, where <foo> is the system call.
	; The arguments to the system call are also passed in registers:
	;	"The kernel interface uses %rdi, %rsi, %rdx, %r10, %r8
	;	and %r9." (ABI, appendix A, section A.2.1)
	; Which explains the previous 'mov' instructions.
	;
	syscall

	; now we quit. Even that requires a system call: exit.
	mov rax, 60
	; The argument to exit is the status code: 0 indicates success,
	; non-zero indicates failure. Instead of
	;	mov rdi, 0
	; we use the equivalent
	;	xor rdi, rdi
	; which makes an XOR of the two operands and stores the result
	; in the first one, following the Intel syntax.
	; XOR'ing a value with itself always gives zero.
	;
	xor rdi, rdi
	syscall
