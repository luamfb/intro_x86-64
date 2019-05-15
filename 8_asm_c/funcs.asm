; Copyright 2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.
;

; funcs.asm: implementation of functions required by main.c.
; These were borrowed from other files in here, but we couldn't use those files
; directly because most contain a _start definition, which conflicts
; with C library's _start.
; Also, we need to mark those functions as global.

global uint2str
global factorial

uint2str:
	push rbp
	mov rbp, rsp

	push rbx
	push r12
	push r13
	push r14
	push r15

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

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx

	mov rsp, rbp
	pop rbp
	ret

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

	mov rbx, rdi
	dec rdi
	call factorial

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
