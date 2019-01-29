AT&T syntax (used by default in GNU assembler) has a few differences from
Intel syntax:
	- immediate values must be prefixed with a dollar sign `$`
	- registers must be prefixed with a percent sign `%`
	- for instructions that have a source and a destination operand,
	their order is reversed: `instr SOURCE, DEST`
	- the addressing mode is in the form `displacment(base,index,scale)`.
	Only the base is required.
	(The address is calculated as base + scale \* index + displacment)
	- whenever specifying the operand's size is required, this is done as
	a single-letter suffix in the instruction's name: `byte`, `word`,
	`dword` and `qword` become suffixes `b`, `w`, `l` (long) and `q`
	respectively.

Those differences are summarized by the table below.

| Intel syntax                         | AT&T syntax |
|:------------------------------------:|:------------------------------------:|
| mov rax, 1                           | mov $1, %rax |
| mov dword [rsp], eax                 | movl %eax, (%rsp) |
| mov word [rbp - 8], dx               | movw %dx, -8(%rbp) |
| lea rcx, qword [rsp + 2 \* rax + 3]  | leaq 3(%rsp,%rax,2), %rcx |
