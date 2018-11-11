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

; (3) jump.asm: conditional and unconditional jumps, eip and eflags.
;
; All code written so far had instructions that were executed sequentially.
; But almost any program needs loops (while, for) and branches (if, else, ...);
; under the hood, those are all jumps.
;
global _start

section .data
	prompt_str: db 'Write something! (max 32 bytes)',0xA
	PROMPT_STRSIZE: equ $ - prompt_str

	unused_str: db "This string won't be printed",0xA
	UNUSED_STRSIZE: equ $ - unused_str

	less_str: db 'The input string has less than 16 bytes',0xA
	LESS_STRSIZE: equ $ - less_str

	more_str: db 'The input string has 16 bytes or more',0xA
	MORE_STRSIZE: equ $ - more_str

section .bss
	buf: resb 32
	BUF_SIZE: equ 32 ; keep the same as above

section .text
_start:
	; write the prompt string
	mov rax, 1 ; __NR_write
	mov rdi, 1 ; stdout
	mov rsi, prompt_str
	mov rdx, PROMPT_STRSIZE
	syscall

	; jmp: unconditional jump. This instruction makes execution deviate from
	; its usual path, in such a way that the instruction after my_label
	; will be executed next. (This is the same as 'goto' in C.)
	; But how does that work?
	; From the basic architecture manual, section 3.5:
	;
	; "The instruction pointer (EIP) register contains the offset in the
	; current code segment for the next instruction to be executed.
	; It is advanced from one instruction boundary to the next
	; in straight-line code or it is moved ahead or backwards by a number
	; of instructions [...]"
	;
	; So the address of the next instruction is stored in this special
	; register, eip. The manual goes on:
	;
	; "The EIP register cannot be accessed directly by software; it is
	; controlled implicitly by control-transfer instructions
	; (such as JMP, Jcc, CALL, and RET), interrupts, and exceptions."
	;
	; This means we can't use eip with the mov instruction, i.e.
	; 'mov eip, <label>' is illegal. However, 'jmp <label>' has the same
	; effect as that.
	;
	jmp my_label

	; because of the previous jump, these instructions won't be executed.
	; (If they were to be, they would print unused_str.)
	mov rax, 1
	mov rdi, 1
	mov rsi, unused_str
	mov rdx, UNUSED_STRSIZE
	syscall

	; we need to use labels to know where to jump to.
	; The labels in the .text section store the address of the instruction
	; immediately following them.
my_label:
	; ask the user for input.
	xor rax, rax ; __NR_read == 0
	xor rdi, rdi ; stdin == 0
	mov rsi, buf
	mov rdx, BUF_SIZE
	syscall

	; The number of bytes that have been read is returned by the
	; read system call, so it's on rax now. We store this value in rbx,
	; which won't be altered by the next system calls.
	mov rbx, rax

	; now we see whether the input has less than 16 bytes.
	; we compare the input size in rbx with 16, through 'cmp'.
	;
	; cmp subtracts the operands, but discards the result, storing only
	; some info about it in a special register: eflags.
	; eflags stores several flags, but we're mostly interested in two:
	; the zero flag and the sign flag.
	; From the basic architecture manual, section 3.4.3.1:
	;
	; "ZF (bit 6) Zero flag - Set if the result is zero; cleared otherwise.
	; SF (bit 7) Sign flag - Set equal to the most-significant bit of
	; the result, which is the sign bit of a signed integer.
	; (0 indicates a positive value and 1 indicates a negative value.)"
	; 
	; These two flags, along with 'cmp', are enough to know whether
	; x - y == 0 <=> x == y and whether x - y < 0 <=> x < y.
	; This is enough to compare two integers in any possible way.
	;
	cmp rbx, 16

	; conditional jump: if the previous comparsion instruction gives a
	; 'greater than or equal to' result, jump to the address stored in
	; the operand label; otherwise, execute the next instruction as usual.
	; Just like with 'jmp', this is also changes the value of eip.
	; There are several instructions for conditional jumps, which are
	; grouped as 'Jcc' in the instruction set. For the 'jl' instruction,
	; the instruction set says:
	; "JL rel8	[...]		Jump short if less (SF != 0F)"
	jl less_16

	; if we're here, the previous jump didn't happen, so the input must
	; have 16 bytes or more.
	mov rax, 1 ; __NR_write
	mov rdi, 1 ; stdout
	mov rsi, more_str
	mov rdx, MORE_STRSIZE
	syscall

	; if it wasn't for this jump, the instructions after the label
	; less_16 would be executed, so it would simultaneously print
	; that the input has less than 16 bytes, but also that it has
	; 16 or more. That's not what we want.
	; Note that these two jumps effectively implement an if-else; in C,
	; this would be something like
	;	if(size > 16) {
	;		/* print more_str */
	;	} else {
	;		/* print less_str */
	;	}
	;
	jmp size_printed

less_16:
	; if we're here, the conditional jump did happen, and the input has
	; less than 16 bytes
	mov rax, 1 ; __NR_write
	mov rdi, 1 ; stdout
	mov rsi, less_str
	mov rdx, LESS_STRSIZE
	syscall

size_printed:
	; iterate over buf, adding 1 to each byte.
	; but first, we temporarily decrease the buf's size by 1,
	; because we don't want to touch its last character (the newline).
	dec rbx ; dec: decrement

	; The following code is equivalent to:
	;	for(i = 0; i < size; i++) {
	;		str[i]++;
	;	}
	;
	xor rcx, rcx
loop_begin:
	; if the condition i < size is false, i.e. if i >= size,
	; get out of the loop at once. If we only made this comparison
	; at the bottom of the loop, we would have something akin to a
	; do ... while instead.
	;
	cmp rcx, rbx
	jge loop_done

	inc byte [buf + rcx] ; inc: increment (++)

	inc rcx ; i++

	; jump to loop_begin's address, starting a new iteration of the loop
	jmp loop_begin

loop_done:
	; restore the string's size
	inc rbx

	; finally, print the string...
	mov rax, 1 ; __NR_write
	mov rdi, 1 ; STDOUT
	mov rsi, buf
	mov rdx, rbx
	syscall

	; ...and quit!
	mov rax, 60
	xor rdi, rdi
	syscall
