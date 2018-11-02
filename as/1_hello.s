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

.global _start

.data
	/*
	 * The directive .ascii declares a non-null-terminated string.
	 * Note that directive understand C-like backslash escapes.
	 */
	str: .ascii "hello, world\n"

	/* The lone dot is the address the assembler is currently at */
	.equ	STRSIZE, . - str

	.equ	STDOUT, 1

.text
_start:
	mov $1, %rax
	mov $STDOUT, %rdi
	/*
	 * In AT&T syntax, addresses must also be prefixed with '$',
	 * because
	 *	mov str, %rsi
	 * would mean instead 'move the first 8 bytes at the address str
	 * to %rsi'.
	 */
	mov $str, %rsi
	mov $STRSIZE, %rdx
	syscall

	mov $60, %rax
	/*
	 * the following instructions makes an XOR of the
	 * two operands and stores the result in the second one,
	 * following the AT&T syntax.
	 */
	xor %rdi, %rdi
	syscall
