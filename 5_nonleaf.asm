; Copyright 2018-2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.
;

; (6) nonleaf.asm: non-leaf functions and callee-saved registers
;
; Non-leaf functions require some extra work than leaf functions.
; We present them here. With this, you should be able to write any function
; in assembly x86_64.

global _start

section .bss
	BUF_SIZ: equ 64
	buf1: resb 64
	buf2: resb 64

section .text
_start:
	; The first function we call is uint2str - which, as the name implies,
	; converts an unsigned integer to a string.
	; Calling a non-leaf function works just the same.
	;
	mov rdi, 40579
	mov rsi, buf1
	mov rdx, BUF_SIZ
	call uint2str

	; write buf1
	mov rdx, rax ; uint2str's return value: the number of bytes written
	mov rax, 1 ; __NR_write
	mov rdi, 1 ; stdout
	mov rsi, buf1
	syscall

	; this function takes just one argument.
	mov rdi, 5
	call factorial

	; convert factorial's return value (in rax) to a string, passing it
	; as the first parameter to uint2str.
	mov rdi, rax
	mov rsi, buf2
	mov rdx, BUF_SIZ
	call uint2str

	; write buf2; pretty much the same as above.
	mov rdx, rax
	mov rax, 1 ; __NR_write
	mov rdi, 1 ; stdout
	mov rsi, buf2
	syscall

	; quit
	mov rax, 60
	xor rdi, rdi
	syscall

; size_t uint2str(unsigned int n, char *buf, size_t bufsize);
;	writes the string corresponding to the number n in buf,
;	writing no more than bufsize bytes.
;	Returns the number of bytes written.
;
uint2str:
	; The two instructions below appear at the beginning of nearly all
	; non-leaf functions. These are often called the prologue of a function.
	;
	; When a function returns, some of the registers must have the same
	; value they had when the function was called. Those are named
	; "callee-saved registers". Which registers are callee-saved is defined
	; by the OS's ABI.
	; It doesn't matter whether the function changes these registers during
	; its execution, but if it does, they must be restored to their original
	; values. To that end, we must store their original values somewhere
	; - and that somewhere is also the stack. We store them explicitly with
	; the PUSH instruction, which explains the 'push rbp' below, because
	; rbp is one of the callee saved registers.
	;
	push rbp ; store the previous value of rbp in the stack
	; 
	; There is one crucial detail we haven't mentioned so far.
	; We've mentioned the stack - but where is the stack top stored?
	; It's in a register: rsp (SP meaning Stack Pointer).
	; In fact, this is what the PUSH instruction does with a 64-bit operand
	; (from the instruction set):
	;
	;"
	;IF StackAddrSize = 64
	;THEN
	;	IF OperandSize = 64
	;	THEN
	;		RSP <- RSP - 8;
	;		Memory[SS:RSP] <- SRC; (* push quadword *)
	; [...]
	;"
	;
	; Two things are noteworthy in this pseudocode. First, RSP actually has
	; its value subtracted when something is PUSH'd - meaning that lower
	; addresses are closer to the stack top, i.e. the stack is
	; "upside down". Second, the address of RSP is accessed in the segment
	; register SS, which stands for Stack Segment (makes sense, right?)
	;
	; rsp is also a calee-saved register, so we also have to store its value
	; somewhere to restore it later. (Actually, this is not always needed,
	; but we usually store rsp anyway.)
	; Unlike eip, rsp is not a special register: it's a general purpose one.
	; It can therefore be used with all instructions that accept
	; general purpose registers as arguments, including MOV.
	
	; Instead of pushing rsp to the stack, we store its value on rbp.
	; (BP stands for Base Pointer.) We can do this because we've already
	; stored the previous value of rbp with 'push rbp', above.
	; We use rbp so we know that all addresses in the range of those
	; stored by rbp + 8 and rsp are addresses belonging to this function's
	; portion of the stack (rbp + 8 because of the PUSH above).
	; That portion is called stack frame.
	;
	mov rbp, rsp ; store the current stack top at rbp

	; push the remaining callee saved registers to the stack, so we can
	; restore them before returning.
	; (Note that all of those PUSH instructions will change rsp's value.)
	;
	; Note: we can keep callee-saved registers unaltered by simply not
	; changing them. That's why we didn't need these PUSH instructions
	; in leaf functions: you only need to push the calee-saved registers
	; you'll change, so in leaf functions there's a good reason not to use
	; these registers, and no good reason to use them.
	; However, a non-leaf function calls another function, and we want to
	; make sure our local variables are not changed in the function we'll
	; call. To that end, we can either store those variables
	;
	;	(1) in the stack, or
	;	(2) in callee-saved registers.
	;
	; We've chosen (2), because accessing stuff from registers is quicker
	; than from memory; though if we had too many variables to store,
	; we'd have to resort to (1). (This is a decision the compiler does
	; for you when using high level languages.)
	;
	push rbx
	push r12
	push r13
	push r14
	push r15

	; Store the arguments passed to us in callee-saved registers.
	; As per the SysV calling convention, these arguments will be in rdi,
	; rsi and rdx respectively.
	;
	; (Note that, since we're writing both this function and all the ones
	; that call it, we could have deviated from the calling convention
	; if we wanted to - as long as both the caller and the callee agree
	; on where the arguments should be, it really doesn't matter.
	; But there will be times when our code needs to call functions written
	; by someone else; then, the easiest way to make these our caller agree
	; with their callee is to stick to the calling convention.)
	;
	mov r12, rdi ; n
	mov r13, rsi ; buf
	mov r14, rdx ; bufsize

	xor r15, r15 ; i = 0 (counter)
	mov rax, r12 ; rax = n

.loop:
	; iterate over the number mod 10 to get the digits in reverse order

	cmp rax, 0
	je .done	; if(n == 0) break;
	cmp r15, r14
	jge .done	; if(i >= bufsize) break;

	xor rdx, rdx
	mov rdi, 10
	div rdi
	; now n%10 is in rdx and n/10 is in rax.
	; Since we're using rax to store n, that was equivalent to
	;	n /= 10; rdx = n % 10;
	;
	; n%10 is between 0 and 9, so that fits in a byte.
	; we add '0' (the ascii value of the character 0) to get a value
	; from '0' to '9'
	;
	add dl, '0'
	mov byte [r13 + r15], dl ; write that value to the string

	inc r15		; i++
	jmp .loop
.done:
	; append a newline to the string
	mov byte [r13 + r15], 0x0a
	inc r15

	; now we've written the string to buf, but it's reversed
	; (the last digit appears first), so we call revstr to fix it.
	;
	mov rdi, r13 ; buf
	lea rsi, [r15 - 1] ; number of chars written -1 (don't include the newline)
	call revstr

	mov rax, r15 ; return value: the counter

	; restore callee saved registers, in the reverse order they were pushed,
	; with the POP instruction. As expected, POP retrieves a value from
	; the stack, stores it in its argument, and updates the stack top:
	; (again from the instruction set)
	;
	;ELSE IF StackAddrSize = 64
	;THEN
	;	IF OperandSize = 64
	;	THEN
	;		DEST <- SS:RSP; (* Copy quadword *)
	;		RSP <- RSP + 8;
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx

	; undo the prologue: these two are often called the function's epliogue.
	; First, retrieve the value old value of rsp from rbp...
	mov rsp, rbp
	; ...then restore rbp from the stack. This instruction also adds 8 to
	; the stack pointer, thus restoring rsp to the value it was right after the
	; CALL instruction, which is vital to make the following RET work.
	pop rbp
	; same as before.
	ret

; unsigned int factorial(unsigned int n);
;	Returns the factorial of n.
;
; This is here just to show an example of recursive function.
; It's not too different from a normal non-leaf function, though.
;
factorial:
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15

	mov r12, rdi ; n

	; recursion base: n == 0
	cmp r12, 0
	je .zero

	; again, we put our argument in a callee saved register to make it
	; survive to the function call
	;
	mov rbx, rdi
	dec rdi
	call factorial ; call itself

	; here, we have returned from the recursive call.
	;
	; again, "mul src" is equivalent to "rdx:rax = rax * src"
	xor rdx, rdx
	mul rbx

	; ideally, we should check if the multiplication above overflowed...

	jmp .done
.zero:
	mov rax, 1 ; 0! = 1
.done:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	mov rsp, rbp
	pop rbp
	ret

; void revstr(char *s, size_t size);
;	reverses the bytes of the array s, which has size bytes.
;
; This is the same function from the previous file.
revstr:
	xor r8, r8
	lea r9, [rsi - 1]

.loop:
	cmp r8, r9
	jge .done

	; swap s[r8] and s[r9]
	mov cl, byte [rdi + r8]
	xchg cl, byte [rdi + r9]
	mov byte [rdi + r8], cl

	inc r8
	dec r9
	jmp .loop
.done:
	ret

; vim: set ft=nasm:
