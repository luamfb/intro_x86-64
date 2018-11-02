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
 * Note: this is simply a translation of the nasm version to the AT&T syntax,
 * which 'as' (the GNU assembler) uses by default.
 * Please refer to the nasm/ folder to see the full commented version.
 */

/*
 * With the GNU assembler (as), any assembler directive must start with a dot '.'
 */
.global _start

.data
	/* .byte is similar to db  */
	my_arr: .byte 0x12,0x34,0x56,0x78,0x90
	/*
	 * the .equ directive in as has a slightly different syntax,
	 * in that it doesn't require a label; the syntax is
	 *	.equ SYMBOL, <value>
	 */
	.equ UNUSED, 3

.text
_start:
	/*
	 * In the AT&T syntax, the source and destination operand are
	 * inverted (when compared to the Intel syntax):
	 *	<instr> SOURCE, DEST
	 * Also, immediate values must be prefixed with '$'
	 * and registers, with '%'.
	 */
	mov $0, %rax

	mov $0x12345678, %eax

	mov $0xabcd, %eax

	mov $0x12, %al

	mov $0x34, %ah

	mov $60, %rax
	xor %rdi, %rdi
	syscall
