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

global _start

; (2) input.asm: the I in I/O
;
; the previous file was a "hello world" program, which shows how output
; works. Here we show input, with a program that reads from stdin and
; prints it back to stdout.
;

section .data
	STDIN: equ 0
	STDOUT: equ 1

; we haven't used this section before: this is for unitialized space
; (meaning we can't tell its contents at first), which gets reserved
; when the program starts.
section .bss
	; resb: reserve bytes. (The argument is the number of bytes.)
	buf: resb 64
	BUF_SIZE: equ 64 ; keep the same number as above

section .text
_start:
	; output works through a system call (write), and so does input,
	; through the read system call. From read's manpage:
	;	ssize_t read(int fd, void *buf, size_t count);
	;	[...]
	;	read() attempts to read up to count bytes from file
	;	descriptor fd into the buffer starting at buf.
	;
	; Also, the input may have more bytes than count: the extra bytes
	; won't be read. (Try it out!)
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
	; write the number of bytes we read.
	; System calls always write their return value to rax.
	; Since we need to write the number of the next system call
	; to that register, we store the value in a different one.
	;
	mov rbx, rax

	; now, write it back to stdout
	mov rax, 1 ; __NR_write
	mov rdi, STDOUT
	mov rsi, buf
	mov rdx, rbx
	syscall

	; finally, we quit.
	mov rax, 60 ; __NR_exit
	xor rdi, rdi
	syscall

; vim: set ft=nasm:
