; Copyright 2018-2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.
;

; (2) addr.asm: addressing mode, mov and lea, etc
global _start

section .data
	str:	db '0123456789',0xA
	strsiz:	equ $ - str
	STDOUT:	equ 1

section .text
_start:
	; we want to print str several times after making changes
	; to some of its bytes, to make sure the code works.
	;
	mov rdx, strsiz
	; copy the address of str to rsi. mov "doesn't know" it's an address
	; because the addressing mode wasn't used.
	;
	mov rsi, str
	mov rdi, STDOUT
	mov rax, 1	; __NR_write

	; rdx, rsi, and rdi will not be changed through most of this code,
	; becuase we'll make a lot of syscalls using these same arguments,
	; so we might as well not touch these registers.
	; (syscalls do not change the contents of general purpose registers,
	; except for rcx, r11 and rax).
	;
	syscall

	; In Intel syntax, the addressing mode is denoted by
	; square brackets []. For example,
	;	mov [rsi], 3
	; This would be equivalent, in C, to
	;	*rsi = 3;
	; (assuming rsi were a variable you could use in C).
	; This means we write 3 to the address whose value is in rsi,
	; as if we were dereferencing a pointer. Needless to say,
	; if the address is not valid, you'll get a segmentation fault.
	;
	; There's a problem with this, though. How many bytes do we want
	; to write? (Keep in mind that, though rsi is 8 bytes, that's the
	; size of the address, not the operand.)
	; In C, we never have to ask that question, because C has types,
	; and each type has a size in bytes. For instance:
	;	int *x;
	;	x = /* some valid address */
	;	*x = 3;
	; Here the answer to our question is obvious: the assignment writes
	; sizeof(int) bytes. However, there's no such thing as types
	; in assembly, so we must write the operand's size explicitly, say
	;	mov byte [rsi], 3
	; we could also use 'word' for 2 bytes and 'dword' (double word)
	; for 4 bytes.
	; (as a side note: intel syntax generally requires one to write
	;	mov byte ptr [rsi], 3
	; the 'ptr' is to make it explicit it's an address, but that's
	; redundant since we're using the addressing mode anyway!
	; So nasm decided to remove the 'ptr' keyword altogether.)
	;

	mov byte [rsi], 'a'
	; syscalls use rax as return register, so we need to restore
	; rax to __NR_write = 1 every time.
	mov rax, 1
	syscall

	mov word [rsi], 'bc'
	mov rax, 1
	syscall

	mov dword [rsi], 'defg'
	mov rax, 1
	syscall

	; So far we've simply accessed the address at one register,
	; but you can make arithmetic in the addressing mode; that's
	; the main reason why this mode is useful.
	; From the basic architecture manual:
	; "In 64-bit mode, a memory operand can be referenced by
	; a segment selector and an offset. [...]
	; The offset part of a memory address in 64-bit mode can be
	; specified directly as a static value or through an address
	; computation made up of one or more of the following components:
	;	Displacement -- An 8-bit, 16-bit, or 32-bit value.
	;	Base -- The value in a 64-bit general-purpose register.
	;	Index -- The value in a 64-bit general-purpose register.
	;	Scale factor -- A value of 2, 4, or 8 that is multiplied
	;	by the index value."
	; In intel syntax, this is written as:
	;	[base + scale * index + displacement]
	; (most of these are optional; see below).
	;
	mov byte [rsi], 'h'		; base only

	mov rax, 1
	syscall

	mov byte [str], 'i'		; displacement only (constant)
	; displacement only
	; (constant as well; will be computed when assembling)
	mov byte [str+1], 'j'
	mov rax, 1
	syscall

	mov rbx, 3
	mov byte [rsi+2], 'k'		; base and displacement
	mov byte [rsi+rbx], 'l'		; base and index
	mov byte [rsi+2*rbx], 'm'	; base, scale and index
	mov byte [rsi+2*rbx+2], 'n'	; base, scale, index and displacement

	mov rax, 1
	syscall

	; We know that
	;	mov rax, [addr_expr]
	; would be equivalent, in C, to
	;	rax = *(addr_expr);
	; meaning it copies whatever is in the address addr to rax.
	; But what if we needed to use the artihemtic provided by the
	; addressing mode, but copy the address itself, instead of its
	; contents? That's when we use the lea (load effective address):
	;	lea rax, [addr_expr]
	; would be equivalent to
	;	rax = (addr_expr);
	;
	mov rbx, 2
	lea rsi, [str+2*rbx]	; str+4

	; because of the arithmetic possible in the addressing mode,
	; lea is sometimes used with expressions
	; which aren't addresses at all. For instance, we know that
	;	lea rcx, [rax + 2 * rbx + 8]
	; will load rcx with rax + 2 * rbx + 8. Whether this is a
	; valid address or not doesn't change anything: unlike mov,
	; lea never tries to access that location.
	; It wouldn't be possible to do such calculation in a single
	; instruction without using lea. That's not its original purpose,
	; but hey, it works!
	;
	mov rbx, -2
	lea rdx, [strsiz+2*rbx]	; use strsiz-4 as size in the write syscall

	mov rax, 1
	syscall

	; TODO segment registers

	xor rdi, rdi
	mov rax, 60
	syscall

; Exercises
;
; === Your Turn ===
;	- Write a program that reads a string from stdin, changes the character
;	in the middle of that string to a newline, then prints it again.
;	(The "middle" can be obtained halving the string's size, which is
;	returned by the read sysem call.)
;
;	- Use the addressing mode to calculate 3*n + 1, where n is the value of
;	a register of your choice.
;

; vim: set ft=nasm:
