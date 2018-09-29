/*
 * Copyright 2018 Luana Carmo M de F Barbosa
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
/*
 * (0) basic: basic assembly stuff.
 * The program doesn't do anything useful, it just explains the outline
 * of assembly code.
 *
 * Please read (at least) the sections 'System requirements' and
 * 'References' of README first.
 */

/*
 * With the GNU assembler (as), anything starting with a dot '.'
 * is an assembler directive, i.e. an action to be taken when assembling,
 * not when executing.
 * This tells the assembler to export the '_start' symbol so the
 * linker will be able find it later.
 */
.global _start

/*
 * Every program in ELF (Executable and Linking Format, default in Linux)
 * has several sections. You can see them with
 *       $ objdump -h <path_to_program>
 * There are many, but the sections we're interested about are
 *       data: global variables
 *       bss: space reserved at program startup
 *       text: CPU instructions (more on that later)
 * These directives are used to specify their repsective sections.
 */
.data
	/*
	 * Anything that's on the beginning of a line and is followed by
	 * a colon ':' is a label. Labels are meant to store an address.
	 * here my_arr stores the address of the first byte declared by
	 * the .byte directive. In other words, this would be equivalent
	 * to the C code
	 *	char my_arr[] = {0x12,0x34,0x56,0x78,0x90};
	 * Note that .byte writes its arguments to the resulting program,
	 * i.e. an hexdump of the executable would show these bytes.
	 */
	my_arr: .byte 0x12,0x34,0x56,0x78,0x90
	/*
	 * the .equ directive sets a name to the value of an expression.
	 * Because this is a compiler directive, UNUSED is not written to
	 * the resulting program. This is more or less similar to
	 * #define in C.
	 */
	.equ UNUSED, 3

.text
/*
 * The _start label has a special meaning: it's the program's entry point,
 * i.e. the first instruction to be executed is at this address.
 */
_start:
	/*
	 * All these are instructions, i.e. operations the CPU knows how
	 * to carry out directly. There's a full list of them in the
	 * instruction set, but we'll only use a dozen or so.
	 * Instructions are separated from their operands by whitespace,
	 * and the operands are separated from other with commas, like so:
	 *	<instr> <operand1>, <operand2>, ..., <operand_n>
	 * The following instructions are 'mov', which simply copy data.
	 * In case of such instructions, which have a source and
	 * a destination operand, the AT&T syntax (which 'as' uses)
	 * dictates the first operand is the source, and the second is
	 * the destination:
	 *	<instr> SOURCE, DEST
	 * Generally, the source and destination operands can be either
	 * an address or a register - a small storage that lives inside
	 * the CPU. The source can also be an immediate value, i.e.
	 * a simple number.
	 *
	 * Immediate values and registers must be prefixed with '$'
	 * and registers, with '%'.
	 */
	mov $0, %rax /* moves the value 0 to regsiter rax */

	/*
	 * There are several registers avaliable on x86_64. Some serve
	 * specific purposes (e.g. registers for storing floating point
	 * numbers), while others are called "general purpose" registers.
	 * There are 16 of them:
	 *
	 *	%rax: accumulator
	 *	%rbx: base
	 *	%rcx: counter
	 *	%rdx: destination
	 *	%rsp and %rbp: stack pointer and base pointer
	 *	%rsi and %rdi: source and destination index
	 *	%r8 through %r15: lack of creativity
	 *
	 * The prefix 'r' in all those mean we want to use all 64 bits
	 * in the registers. For all those, except r8 through r15,
	 * it's possible to access:
	 *	- the lowest 32 bits with 'e' prefix, e.g. %eax, %ebp
	 *	- the lowest 16 bits without any prefix, e.g. %ax, %si
	 * Also, for registers %rax through %rdx, it's possible to access:
	 *	- the lowest byte with the 'l' prefix, replacing the
	 *	trailing 'x', e.g. %al
	 *	- the highest byte in the 16 bits with the 'h' prefix, in
	 *	the same way as above, e.g. %ah
	 * This is summarized in figure 3-5 of section 3.4.1,
	 * basic architecture.
	 *
	 * (Note: we use 'byte' as a synonym of '8 bits', because it
	 * indeed is in the x86 architecture.)
	 */
	mov $0x12345678, %eax /* copies 4 bytes to %eax */
	/*
	 * still copies 4 bytes to %eax: the remaining 2 bytes are filled
	 * with zeroes, i.e. this is the same as
	 *	mov $0x0000abcd, %eax
	 * note that this is different from 'mov $0xabcd, %ax'
	 * in that the previous instruction would only change the lowest
	 * 2 bytes of the register.
	 */
	mov $0xabcd, %eax

	/* copies to the lowset byte: now %ax will be 0xab12 */
	mov $0x12, %al
	/* copies to the highest byte: now %ax will be 0x3412 */
	mov $0x34, %ah

	/*
	 * the code below is a system call to exit cleanly;
	 * we'll explain it in the next file.
	 */
	mov $60, %rax
	xor %rdi, %rdi
	syscall
