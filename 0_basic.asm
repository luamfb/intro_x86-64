; Copyright 2018-2019 Luana Carmo M de F Barbosa
;
; This file is licensed under the CC-BY-SA 2.0 license.
; See LICENSE for details.

; (0) basic: basic assembly stuff.
; The program doesn't do anything useful, it just explains the outline
; of assembly code.
;
; Please read (at least) the sections 'System requirements' and
; 'References' of README first.
;

; This is an assembler directive, i.e. an action to be taken when assembling,
; not when executing.
; This tells the assembler to export the '_start' symbol so the
; linker will be able find it later.
;
global _start

; Every program in ELF (Executable and Linking Format, default in Linux)
; has several sections. You can see them with
;       $ objdump -h <path_to_program>
; There are many, but the sections we'll use are
;
;       data: global variables
;	rodata: global constants (read-only data)
;       bss: space reserved at program startup
;       text: CPU instructions (more on that later)
;
; These directives are used to specify their repsective sections.
;
section .data
	; Anything that's on the beginning of a line and is followed by
	; a colon ':' is a label. Labels generally store addresses.
	; here my_arr stores the address of the first byte declared by
	; the 'db' (declare bytes) directive.
	; In other words, this would be equivalent to the C code
	;
	;	char my_arr[] = {0x12,0x34,0x56,0x78,0x90};
	;
	; Note that db writes its arguments to the resulting program,
	; i.e. an hexdump of the executable would show these bytes. (*)
	;
	my_arr: db 0x12,0x34,0x56,0x78,0x90

	; just as there is db, there's also
	;
	;	dw: declare word (2 bytes),
	;	dd: declare doubleword (4 bytes)
	;	dq: declare quadword (8 bytes)
	;
	; ...among others, but these are the ones we'll use most often.
	; (See the NASM manual, section 3.2.1 for the full list.)
	;
	; It's important to note that all those are little-endian,
	; meaning that the bytes' order gets "reversed": the last byte in the
	; multi-byte value goes first. (*)
	;
	little_endian_beef: dw 0xbeef ; becomes 0xef 0xbe, in that order

	; if we use dw, dd, ..., with less bytes than they expect, the rest
	; of the bytes get filled with zeroes.
	;
	filled_with_zero: dw 0x42 ; becomes 0x42 0x00, in that order

	; becomes 0x76 0x98 0x32 0x54 0xAA 0x00, in that order
	my_arr2: dw 0x9876, 0x5432, 0xAA
	my_arr3: dd 0xdeadbeef, 0xc0ffee ; 0xc0ffee -> 0xee 0xff 0xc0 0x00
	my_arr4: dq 0x0102030405060708, 0x090a0b0c0d0e0f00

	; the equ directive sets a name to the value of an expression.
	; Because this is an assembler directive, UNUSED is not written to
	; the resulting program. This is similar to #define in C.
	;
	UNUSED: equ 3

section .text
; The _start label has a special meaning: it's the program's entry point,
; i.e. the first instruction to be executed is at this address.
;
_start:
	; All these are instructions, i.e. operations the CPU knows how
	; to carry out directly. There's a full list of them in the
	; instruction set, but we'll only use a dozen or so.
	; Instructions are separated from their operands by whitespace,
	; and the operands are separated from other with commas, like so:
	;	<instr> <operand1>, <operand2>, ..., <operand_n>
	; The following instructions are 'mov', which simply copy data.
	; In case of such instructions, which have a source and
	; a destination operand, the Intel syntax (which nasm uses)
	; dictates the first operand is the destination, and the second is
	; the source:
	;	<instr> DEST, SOURCE
	; Generally, the source and destination operands can be either
	; an address or a register - a small storage that lives inside
	; the CPU. The source can also be an immediate value, i.e.
	; a simple number.
	;
	mov rax, 0 ; moves the value 0 to regsiter rax

	; There are several registers avaliable on x86_64. Some serve
	; specific purposes (e.g. registers for storing floating point
	; numbers), while others are called "general purpose" registers.
	; There are 16 of them:
	;
	;	rax: accumulator
	;	rbx: base
	;	rcx: counter
	;	rdx: destination
	;	rsp and rbp: stack pointer and base pointer
	;	rsi and rdi: source and destination index
	;	r8 through r15: lack of creativity
	;
	; The prefix 'r' in all those mean we want to use all 64 bits
	; in the registers. For all those, except r8 through r15,
	; it's possible to access:
	;	- the lowest 32 bits with 'e' prefix, e.g. eax, ebp
	;	- the lowest 16 bits without any prefix, e.g. ax, si
	; Also, for registers rax through rdx, it's possible to access:
	;	- the lowest byte with the 'l' prefix, replacing the
	;	trailing 'x', e.g. al
	;	- the highest byte in the 16 bits with the 'h' prefix, in
	;	the same way as above, e.g. ah
	; This is summarized in figure 3-5 of section 3.4.1,
	; basic architecture.
	;
	; (Note: we use 'byte' as a synonym of '8 bits', because it
	; indeed is in the x86 architecture.)
	;
	mov eax, 0x12345678 ; copies 4 bytes to eax
	; still copies 4 bytes to eax: the remaining 2 bytes are filled
	; with zeroes, i.e. this is the same as
	;	mov eax, 0x0000abcd
	; note that this is different from 'mov ax, 0xabcd'
	; in that the previous instruction would only change the lowest
	; 2 bytes of the register.
	;
	mov eax, 0xabcd

	; copies to the lowset byte: now ax will be 0xab12 (*)
	mov al, 0x12 
	; copies to the highest byte: now ax will be 0x3412 (*)
	mov ah, 0x34

	; and of course, you can make arithmetic too.

	mov rdi, 10
	mov rsi, 7
	mov rbx, 14

	inc rdi		; INC: increment
	dec rsi		; DEC: decrement

	; ADD: adds the two operands and stores the result in the destination
	; one (again, that's the first one, because we're using Intel syntax.)
	;
	add rdi, rbx	; Equivalent to rdi += rbx

	sub rsi, rbx	; SUB: subtract. Equivalent to rsi -= rbx

	; Naturally, we also have instructions for multiplying and dividing
	; integers, but they come with a few catches.
	;
	; First, there's two variants for each: MUL and DIV interpret their
	; operands as unsigned integers, while IMUL and IDIV interpret their
	; operands as signed integers in two's complement.
	; (This changes whether or not the operands' most significant bits are
	; interpreted as sign bits).
	;
	; Second, while both multiplication and division need two numbers,
	; the MUL and DIV instructions take a single operand because they use
	; fixed registers for the other number.
	; For example, when a 64-bit operand is used in
	;
	;	- MUL, the result is rax * <operand>, and it's a 128-bit value
	;	stored in rdx:rax - meaning the 64 lower bits are stored in rdx,
	;	while the 64 upper bits are stored in rax.
	;
	;	- DIV, the operand is the divisor and the dividend is rdx:rax,
	;	meaning it's a 128-bit value whose 64 upper bits are in rdx and
	;	whose 64 lower bits are in rax. The quotient is a 64-bit value
	;	stored in rax, and the remainder is also a 64-bit value, stored
	;	in rdx.
	;
	mov rax, 7
	mov rdx, 4 ; will be overwritten by MUL
	mov rdi, 3

	mul rdi
	; here, rax <- 3 * 7 = 21, rdx <- 0 (*)

	mov rax, 22
	mov rdx, 0
	mov rdi, 4

	div rdi
	; here, rax is floor(22 / 4) = 5, and rdx is 22 mod 4 = 2 (*)

	; finally, we have bitwise operations too.
	mov rdi, 0x35
	mov rsi, 0x44

	and rdi, rsi	; bitwise AND
	or rdi, rsi	; bitwise OR
	xor rdi, rsi	; bitwise XOR

	shr rsi, 2	; right (logical) bitshift: equivalent to rsi >> 2
	shl rsi, 3	; left (logical) bitshift: equivalent to rsi << 3

	; Note that there's SAR for arithmetic right shift.
	; There's also SAL, but it's equivalent to SHL.

	; the code below is a system call to exit cleanly;
	; we'll explain it in the next file.
	;
	mov rax, 60
	xor rdi, rdi
	syscall

; Exercises
;
; === First Things First ===
; Assemble and link this file into a program, then run it.
; (The program should do nothing other than exit cleanly)
;
; === St Thomas' Wisdom ===
; Verify all claims marked with (*).
;	- Print a hexdump of the program to verify db, dw, etc. work as stated,
;	including the endianess.
;	- Run the program in gdb to verify that the instructions work as stated,
;	stepping through each one and printing the affected registers' value
;	as needed. (Refer to the "Debugging" section of README.md to learn how.)
;
; === Changing Stuff and Seeing What Happens ===
;	- Comment out the syscall instruction and run again.
;	- Change DIV's operand to zero and run again.
;

; vim: set ft=nasm:
