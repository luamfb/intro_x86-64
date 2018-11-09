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

; (3) loop.asm: loop using conditional and unconditional jumps
global _start

section .data
	str: db 'abcd',0xA
	STRSIZE: equ $ - str
	STRSIZE_MINUS1: equ STRSIZE - 1

section .text
_start:
	; We're going to iterate over the string adding 1 to each character.
	; In C one would do this with a 'while' or 'for' loop, but there is no
	; such thing in assembly. Instead, one uses jumps only.

	xor rcx, rcx
	; we always use labels to know where to jump to.
loop_begin:
	; comparison: this instruction subtracts the operands, but discards
	; the result, storing only some info about it in a special register:
	; eflags. eflags stores several flags, but we're mostly interested
	; in two: the zero flag and the sign flag.
	; From the basic architecture manual, section 3.4.3.1:
	;
	; "ZF (bit 6) Zero flag - Set if the result is zero; cleared otherwise.
	; SF (bit 7) Sign flag - Set equal to the most-significant bit of
	; the result, which is the sign bit of a signed integer.
	; (0 indicates a positive value and 1 indicates a negative value.)"
	; 
	; What this means is every time you do
	;	if(x > y) { ... }
	; in C, you're actually calculating x - y, and checking the sign of
	; the result. By looking at the sign flag we know whether the result
	; is negative or non-negative, and by looking at the zero flag
	; we know whether it's zero or not. That's what the conditional
	; jumps do (more on it below).
	;
	cmp rcx, STRSIZE_MINUS1

	; conditional jump: if the previous comparsion instruction gives a
	; 'greater than or equal to' result, jump to the address stored in
	; the label 'done'; otherwise, execute the next instruction as usual.
	; There are several instructions for conditional jumps, which are
	; grouped as 'Jcc' in the instruction set. For the 'jge' instruction,
	; the instruction set says:
	; "JGE rel8	[...]		Jump short if greater or equal (SF=0F)"
	;
	jge loop_done

	inc byte [str + rcx] ; increment (add 1) to this byte

	inc rcx ; increment the counter
	; unconditional jump: jump to loop_begin's address
	jmp loop_begin

loop_done:
	; print the string...
	mov rax, 1 ; __NR_write
	mov rdi, 1 ; STDOUT
	mov rsi, str
	mov rdx, STRSIZE
	syscall

	; ...and quit!
	mov rax, 60
	xor rdi, rdi
	syscall
