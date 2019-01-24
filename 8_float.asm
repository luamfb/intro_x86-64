; Copyright 2018-2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.
;

; TODO mention SSE/AVX vs x87 somewhere

; (8) float.asm: floating point numbers
;
; We could've explained this much sooner, but I wanted to use printf()
; and scanf() rather than making float <-> string conversions by hand.
;
; Note: in this file, we use "float" and "double" as synonyms with
; "single-precision floating point number" (4 bytes) and
; "double-precision floating point number" (8 bytes) respectively.

global main

; TODO uncomment and see if it works with PIE
;default rel

extern printf
extern scanf

; rodata: read-only data (global constants)
section .rodata
	; dd: declare dword (32 bits, hence a float). (TODO we should have shown 'dd' in the basics file!)
	; Nasm understands a number literal with a dot as a floating point number
	; and writes the appropiate value.
	; The reason we declare this as a constant here is because we need it to
	; have an address to use with the instructions below.
	flt1: dd 1.0

	prompt: db 'type two floating point numbers (x and y): ',0x0

	; for scanf(), "%f" means float and "%lf" means double; for printf(),
	; "%f" means double, and there there's no way of printing a float
	; directly (not as far as I know).
	;
	scanf_flt_fmt: db '%f',0x0
	scanf_dbl_fmt: db '%lf',0x0
	printf_dbl_fmt: db 'x + y = %f',0xA,0x00

section .text
main:
	push rbp
	mov rbp, rsp

	; TODO explain
	and rsp, -16

	; make room for two doubles, or four floats (though at first we only
	; use two).
	; We would need 16 bytes for that, but even if we needed less we'd still
	; have to subtract 16 because the stack must remain 16-byte aligned.
	;
	sub rsp, 16

	mov rdi, prompt
	call printf

	mov rdi, scanf_flt_fmt
	mov rsi, rsp
	call scanf

	; note: rdi is not a callee-saved register, so we have to set it again
	mov rdi, scanf_flt_fmt
	lea rsi, [rsp + 4]
	call scanf

	; TODO explain
	pxor xmm0, xmm0

	; TODO explain what 'ss' is
	movss xmm0, dword [rsp]
	; TODO say there are other instructions like that called {sub,div,mul}ss
	addss xmm0, dword [rsp + 4]

	; convert the result to double before calling printf()
	;
	; TODO explain
	cvtss2sd xmm0, xmm0

	mov rdi, printf_dbl_fmt
	call printf

	; now we do the same with doubles

	mov rdi, prompt ; FIXME maybe we should use a different prompt for each size?
	call printf

	mov rdi, scanf_dbl_fmt
	mov rsi, rsp
	call scanf

	mov rdi, scanf_dbl_fmt
	lea rsi, [rsp + 8]
	call scanf

	; this is just the same as before, but instead of scalar single-precision
	; (SS) we use scalar double-precision (SD)
	movsd xmm0, qword [rsp]
	addsd xmm0, qword [rsp + 8]

	; result is already a double, no conversion needed
	mov rdi, printf_dbl_fmt
	call printf

	; TODO long double (how do we even do that?)

	; TODO packed floating point numbers (vectors, whatever)
	; we also have to mention that xmm0 is just a part of ymm0 which is
	; just a part of zmm0

	xor rax, rax
	mov rsp, rbp
	pop rbp
	ret

; vim: set ft=nasm:
