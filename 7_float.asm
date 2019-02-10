; Copyright 2018-2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.
;

; (7) float.asm: floating point numbers, x87/SSE/AVX, byte alignment
;
; We could've explained this sooner, but I wanted to be able to use printf()
; and scanf() rather than making float <-> string conversions by hand.
;
; Note: in this file, we use "float" and "double" as synonyms with
; "single-precision floating point number" (4 bytes) and
; "double-precision floating point number" (8 bytes) respectively.

global main

extern printf
extern scanf

section .rodata
	prompt_flt: db 'type a float (x, result will be x+1): ',0x0
	prompt_dbl: db 'type a double (x, result will be x-1): ',0x0

	; for scanf(), "%f" means float and "%lf" means double; for printf(),
	; "%f" means double, and there there's no way of printing a float
	; directly (not as far as I know).
	;
	scanf_flt_fmt: db '%f',0x0
	scanf_dbl_fmt: db '%lf',0x0
	printf_dbl_fmt: db 'result = %f',0xA,0x00

	printf_dbl_vec2_fmt: db '%f, %f',0xA,0x00
	printf_dbl_vec4_fmt: db '%f, %f, %f, %f',0xA,0x00

	; dt: declare extended precision (80-bit) floating point number.
	; (A long double is generally a 80-bit floating point number.)
	;
	ldbl1: dt 2.222222222222222222
	ldbl2: dt 7.777777777777777777

	; long double format.
	; We use 18 digits of precision here because in 80-bit floating point
	; numbers, the mantissa has 64 bits, and 2^(-64) < 10^(-18).
	;
	printf_ldbl_fmt: db '%.18Lf',0xA,0x00

	; Align the current address in a 16-byte boundary,
	; that is, make the current address divisible by 16, by declaring a
	; bunch of useless bytes for padding.
	; A few notes on align:
	; "Both macros require their first argument to be a power of two [...]
	; ALIGN and ALIGNB, being simple macros, perform no error checking:
	; they cannot warn you if their first argument fails to be a power of
	; two [...]
	; A final caveat: ALIGN and ALIGNB work relative to the beginning of
	; the section, not the beginning of the address space in the final
	; executable. Aligning to a 16−byte boundary when the section you’re in
	; is only guaranteed to be aligned to a 4−byte boundary, for example,
	; is a waste of effort." (NASM manual, section 4.11.12)
	;
	align 16

	; dword = 32 bits, hence, a float.
	; Nasm understands a number literal with a dot as a floating point
	; number and writes the appropiate value.
	;
	flt1: dd 1.0
	; qword = 64 bits, hence, a double.
	dbl1: dq 1.0

	; we use this again because we also need flt_vec4_1 to be 16-byte
	; aligned. We've declared 1 float and 1 double, which adds
	; 4 + 8 = 12 bytes, so we need more 4 bytes of padding.
	align 16

	flt_vec4_1: dd 2.0, -1.0, 3.5, 4.2
	flt_vec4_2: dd 1.2, 3.4, -1.2, 7.8

	dbl_vec2_1: dq 2.0, -1.0
	dbl_vec2_2: dq 1.2, 3.2

	; these two need to be in a 32-byte alignment
	align 32
	dbl_vec4_1: dq 4.7, -6.8, 3.1, 6.7
	dbl_vec4_2: dq 8.4, 9.2, 4.9, -1.6

section .text
main:
	push rbp
	mov rbp, rsp

	; these are separate functions not only for the organization's sake,
	; but also to show that they actually work using different stack
	; byte alignments.
	;
	call sse
	call avx
	call x87

	xor rax, rax

	mov rsp, rbp
	pop rbp
	ret

; void sse(void);
sse:
	; SSE instructions deal with the XMM registers: xmm0 through xmm7
	; in 32-bit mode, and additionally xmm8 through xmm15 in 64-bit mode.
	; XMM registers are 128-bit (16-byte) long.
	; (Basic architecture, sections 10.2.1 and 10.2.2)

	push rbp
	mov rbp, rsp

	; Align rsp's address to a 16-byte alignment. The reason for this
	; is the same as for the use of those align macros back there: we want
	; to use rsp indexed addresses as arguments for SSE instructions,
	; and those must be 16-byte aligned.
	;
	; But how does that align rsp to a 16-byte boundary?
	; An address that's aligned to a (2^N)-byte boundary is one whose
	; value is divisible by 2^N.
	; It turns out, because of how two's complement work, that -2^N is
	; a value with al bits 1, except for the last N bits, which are all 0.
	; For instance, with -16:
	; 
	; 16 = 0..010000 --(1's compl)--> 1..101111 --(+1)--> 1..110000 = -16
	;
	; So we could've written the instruction below as "AND rsp, 0xff..f0",
	; with 31 Fs. We didn't, because if you leave a single F out,
	; it'd be equivalent to "AND rsp, 0x0f..f0" and no good can possibly
	; come out of that. Besides, though it may seem weird at first,
	; the intention is very clear when you write an AND with a negative
	; power of two like that.
	;
	; Therefore, the AND below is zero'ing out the last 4 bits of rsp,
	; which makes it divisible by 2^4, because that's how the positional
	; system work: if the N last digits of a number written in base B
	; are all 0, then the number is divisible by B^N. (The proof is trivial
	; - yes, I know everyone says that, but for real this time.)
	; Since we're talking about the last 4 bits being zero, N=4 and B=2.
	;
	; (As a side note: sometimes you can omit the prologue and epliogue
	; of non-leaf functions if you're careful enough.
	; We can save ourselves from storing rsp in rbp if we can undo all
	; changes to rsp's value throughout the function.
	; For instance, if rsp is only manipulated through PUSH and SUB
	; instructions, we can ADD the same value that was SUB'd and have the
	; same number of POP instructions than PUSH ones, and that's enough to
	; restore rsp to its original value. Here, though, this AND cannot be
	; easily reverted, so it forces us to store the previous value of rsp
	; somewhere.)
	;
	and rsp, -16

	; make room for 4 floats, or 2 doubles.
	; We need 16 bytes for that, but even if we needed less we'd still
	; have to subtract a multiple of 16 because the stack must remain
	; 16-byte aligned.
	;
	sub rsp, 16

	mov rdi, prompt_flt
	call printf

	mov rdi, scanf_flt_fmt
	lea rsi, [rsp]
	call scanf

	; Since xmm0 is 128-bit long, and at first we only use its lowest bits,
	; we zero it out first.
	; We have to use PXOR instead of XOR because the latter expects
	; general purpose registers (rax, rbx, ...) while the former expects
	; XMM registers. (When in doubt, you can check the instruction set.)
	;
	pxor xmm0, xmm0

	; most SSE and AVX instructions have one of the following suffixes:
	;
	;	SS = Scalar Single-precision
	;	PS = Packed Single-precision
	;	SD = Scalar Double-precision
	;	PD = Packed Double-precision
	;
	; As expected, single or double precision means float (4 bytes)
	; or double (8 bytes) respectively.
	; As for scalar versus packed: since XMM registers are 128-bit long
	; (16 bytes), we can fit 2 doubles or 4 floats in one of them.
	; When doing so, we say the numbers are packed. However, we can also
	; store just one float or double per register: when doing so, we say
	; that value is a scalar. (It's called like that as an analogy to the
	; mathematical concepts of scalar and vector, since packed values
	; can be seen as a vector of real numbers).
	;
	movss xmm0, dword [rsp]

	; add the two values. Again, we cannot use the ADD instruction:
	; we must use one of the SSE instructions, and becuase our operands
	; are both scalar and single-precision, then ADDSS it is.
	;
	; Nearly all SSE instructions require memory arguments to be 16-byte
	; aligned, because that's the size of XMM registers.
	; If that requirement isn't met, you'll get a segmentation fault.
	;
	; This is why we needed those align macros back there, and also why
	; we had to declare flt1 in the first place (SSE instructions do not
	; accept immediate values as arguments).
	;
	addss xmm0, [flt1]

	; printf()'s format string expects a double, so convert the result
	; to double before calling printf().
	;
	; (cvt = convert, ss2sd = SS to SD)
	cvtss2sd xmm0, xmm0

	mov rdi, printf_dbl_fmt
	call printf

	; now we do the same with doubles

	mov rdi, prompt_dbl
	call printf

	mov rdi, scanf_dbl_fmt
	lea rsi, [rsp]
	call scanf

	; same as before, but instead of scalar single-precision (SS)
	; we use scalar double-precision (SD)
	movsd xmm0, qword [rsp]
        subsd xmm0, [dbl1]

	; result is already a double, no conversion needed
	mov rdi, printf_dbl_fmt
	call printf


	; Since we have MOVSS, one might expect that for packed floats the
	; instruction would be "movps". It's not, though, because it comes in
	; two flavors: MOVUPS and MOVAPS. 
	; MOVUPS is one of the few SSE instructions that do not require memory
	; arguments to be aligned on a 16-byte boundary, whereas MOVAPS does
	; require that, as usual. (The 'A' and 'U' stand for "Aligned" and
	; "Unaligned", respectively.)
	; However, since we already had to align flt_vec4_1 because of other
	; SSE instructions where we use it, then we might as well use MOVAPS.
	;
	movaps xmm0, [flt_vec4_1]
	mulps xmm0, [flt_vec4_2]

	; move result back to the stack...
	; (we can use MOVAPS here too because rsp is 16-byte aligned too)
	movaps [rsp], xmm0
	; ...so we can move the 4 floats back to separate registers,
	; as scalar values (i.e. unpack them)
	;
	movss xmm0, dword [rsp]
	movss xmm1, dword [rsp+4]
	movss xmm2, dword [rsp+8]
	movss xmm3, dword [rsp+12]
	; again, we have to convert all those values to double because of the
	; printf() format
	;
	cvtss2sd xmm0, xmm0
	cvtss2sd xmm1, xmm1
	cvtss2sd xmm2, xmm2
	cvtss2sd xmm3, xmm3

	mov rdi, printf_dbl_vec4_fmt
	call printf

	; the same with doubles, again.
	; (There's also MOVAPD and MOVUPD)
	movapd xmm0, [dbl_vec2_1]
	divpd xmm0, [dbl_vec2_2]

	movapd [rsp], xmm0
	movsd xmm0, qword [rsp]
	movsd xmm1, qword [rsp+8]

	mov rdi, printf_dbl_vec2_fmt
	call printf

	mov rsp, rbp
	pop rbp

	ret

; void avx(void);
avx:
	; AVX instructions deal with YMM registers: ymm0 through ymm7 in 32-bit
	; mode and also ymm8 through ymm15 in 64-bit mode.
	; YMM registers are 256-bit (32-byte) long.
	; Similar to eax/rax, when using AVX, xmmN is an alias to the lowest
	; 16 bytes of ymmN.
	; (Basic architecture, section 14.1)
	;
	; In the same vein, there's also AVX-512, which introduces 512-bit long
	; registers zmm0 through zmm15, and ymmN is the lowest 32 bytes of zmmN.

	push rbp
	mov rbp, rsp

	; Since AVX uses 32-byte long registers, we'll need to align rsp
	; to 32-byte to use it in AVX instructions.
	and rsp, -32

	; make room for 4 doubles. Again, even if we needed less space,
	; we'd still have to subtract a multiple of 32 here.
	sub rsp, 32

	; AVX instructions are similar to SSE, except we need to prepend them
	; with 'v' so they're econded using the VEX prefix, which allows using
	; the YMM registers as arguments (instruction set, section 2.3.1).
	;
	vmovapd ymm0, [dbl_vec4_1]
	vaddpd ymm0, ymm0, [dbl_vec4_2]

	vmovapd [rsp], ymm0

	; unpack the 4 doubles into separate XMM registers.
	; We can use the instructions prepended with 'v' with XMM registers too:
	; the only difference is the highest 16 bytes of the corresponding YMM
	; register are zero'd out.
	; If you're only using XMM registers, there's no difference between
	; them, but since we were using all of ymm0 I do want to clear its
	; highest bytes.
	;
	vmovsd xmm0, qword [rsp]
	; and we use 'v' here too, just because we can.
	vmovsd xmm1, qword [rsp+8]
	vmovsd xmm2, qword [rsp+16]
	vmovsd xmm3, qword [rsp+24]

	mov rdi, printf_dbl_vec4_fmt
	call printf

	; (ymm0 is not callee-saved, it may have changed when calling printf())
	vmovapd [rsp], ymm0
	vmovapd ymm1, [dbl_vec4_1]

	; AVX also has some more elaborated features like fused add-multiply:
	; this instruction mulitplies the packed doubles in the 2nd and 3rd
	; operands then adds them to those in the 1st operand.
	vfmadd231pd ymm0, ymm1, [dbl_vec4_2]

	vmovapd [rsp], ymm0
	movsd xmm0, qword [rsp]
	movsd xmm1, qword [rsp+8]
	movsd xmm2, qword [rsp+16]
	movsd xmm3, qword [rsp+24]
	mov rdi, printf_dbl_vec4_fmt
	call printf

	mov rsp, rbp
	pop rbp
	ret

; void x87(void);
x87:
	push rbp
	mov rbp, rsp

	; And now for something different!
	; SSE, AVX and the like only have support to floats or doubles.
	; To use long doubles (80-bit), we need to use legacy x87 instructions.
	; (These date way back to the days of floating-point coprocessors...)
	;

	; x87 instructions do not require any form of byte alignment.
	; However, this is still needed because the printf() call may use SSE
	; instructions (it does on my libc implementation).
	;
	and rsp, -16

	; make room for one 80-bit floating point number.
	; (again, only 10 bytes are needed, but we must mantain the alignment)
	;
	sub rsp, 16

	; x87 operates on special "registers", st0 through st7, each of which
	; refer to a certain position in a floating point stack.
	;
	; x87 instructions are all prefixed with an 'f'.
	; Here, we use FLD (LD = load) to push the 80-bit (tword) value
	; at address ldbl1 to the register st0.
	;
	; Note that the TWORD prefix here is mandatory, because most x87
	; instructions can also be used with 32-bit and 64-bit memory locations:
	; "Almost any x87 floating−point instruction that references memory must
	; use one of the prefixes DWORD, QWORD or TWORD to indicate what size
	; of memory operand it refers to." (NASM manual, section 3.1)
	;
	fld tword [ldbl1]
	;
	; We want to load a second long double, but before that, we copy
	; the value at st0 to st1 so it won't be lost. This is done with FST
	; (ST = store).
	;
	fst st1

	; Load the second long double.
	fld tword [ldbl2]

	; add the numbers. Note how we only provide one operand to this
	; instruction: the other one is implicitly st0. Nasm allows you to write
	; it explicitly, though:
	; "For x87 floating−point instructions, NASM accepts a wide range of
	; syntaxes: you can use two−operand forms like MASM supports, or you can
	; use NASM’s native single−operand forms in most cases. For example,
	; you can code:
	;	fadd st1 ; this sets st0 := st0 + st1
	;	fadd st0,st1 ; so does this
	;
	; " (NASM manual, section 3.1)
	;
	; This instruction stores the result back to st0 as well.
	;
	fadd st1

	; FSTP is similar to FST, but also pops the floating point stack.
	; store the value of st0 in the stack (again, as an 80-bit location),
	; so we can print it.
	;
	fstp tword [rsp]

	mov rdi, printf_ldbl_fmt
	mov rsi, rsp
	call printf

	; x87 also allows loading directly some famous constants.
	; This instructions loads pi.
	fldpi

	; And of course, what's the point of storing pi if you can't do
	; trigonometric stuff?
	; This calculates the cosine of st0 and stores the result in that same
	; "register".
	fcos

	; again, so we can print the value
	fstp tword [rsp]

	mov rdi, printf_ldbl_fmt
	mov rsi, rsp
	call printf

	mov rsp, rbp
	pop rbp
	ret

; vim: set ft=nasm:
