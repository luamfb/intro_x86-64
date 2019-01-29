; Copyright 2018-2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.
;

; (1) io.asm: I/O, system calls
; 
; This file shows how to read from stdin and write to stdout in assembly,
; with a simple program that writes a prompt, reads a string and writes it back.
;

global _start

section .data
	; The directive 'db' means 'declare bytes', while the label 'str'
	; stores the address of the beginning of that string.
	; Note the string declared is not null terminated, so we need
	; to keep track of its size, which we do next (with STRSIZE).
	; Also note that 0xA is the ascii value for Line Feed (newline, "\n").
	;
	str: db "Type something and I'll repeat it! (max 64 bytes)", 0xA

	; The lone '$' is the address the assembler is currently at,
	; so by subtracting it from 'str' we get the number of bytes in
	; the declared string (and that still works if we change the string,
	; since it's not a hardcoded size.)
	;
	STRSIZE: equ $ - str

	; File descriptors.
	; A file descriptor is a number used in Unix to refer to an open file.
	; Some special files are always open, and have fixed file descriptors:
	;	stdin: 0
	;	stdout: 1
	;	stderr: 2
	;
	STDIN: equ 0
	STDOUT: equ 1

; We haven't used this section before: this is for unitialized space
; (meaning we can't tell its contents at first), which gets reserved
; when the program starts.
;
section .bss
	; resb: reserve bytes. (The argument is the number of bytes.)
	buf: resb 64
	BUF_SIZE: equ 64 ; keep the same number as above


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

	; output works through a system call, and so does input,
	; through the read system call. From read's manpage:
	;	ssize_t read(int fd, void *buf, size_t count);
	;	[...]
	;	read() attempts to read up to count bytes from file
	;	descriptor fd into the buffer starting at buf.
	;
	; Also, if the input has more bytes than count, the extra bytes
	; won't be read. (Try it out!)
	;

	; note: instead of
	;	mov rax, 0
	; we use the equivalent
	;	xor rax, rax
	; which makes an XOR of the two operands and stores the result
	; in the first one, as is usual in the Intel syntax.
	; XOR'ing a value with itself always gives zero, so those are in fact
	; equivalent.
	;
	xor rax, rax ; __NR_read == 0
	mov rdi, STDIN
	mov rsi, buf
	mov rdx, BUF_SIZE
	syscall

	; again from the read's manpage:
	;	On success, the number of bytes read is returned [...]
	;	It is not an error if this number is smaller than the
	;	number of bytes requested; this may happen for example
	;	because fewer bytes are actually available right now [...]
	;
	; We want to keep track of the return value so we can only
	; write the number of bytes we've read.
	; System calls always write their return value to rax.
	; Since we need to write the number of the next system call
	; to that register, we store the value in a different one.
	;
	mov rbx, rax

	; now, write it back to stdout
	mov rax, 1 ; __NR_write
	mov rdi, STDOUT
	mov rsi, buf
	mov rdx, rbx ; get the size from where we stored it
	syscall

	; now we quit. Even that requires a system call: exit.
	mov rax, 60
	; The argument to exit is the status code: 0 indicates success,
	; non-zero indicates failure.
	; Instead of
	;	mov rdi, 0
	; we use the equivalent
	;	xor rdi, rdi
	; which makes an XOR of the two operands and stores the result
	; in the first one, following the Intel syntax.
	; XOR'ing a value with itself always gives zero.
	;
	xor rdi, rdi
	syscall

; vim: set ft=nasm:
