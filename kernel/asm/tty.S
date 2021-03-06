/* Copyright (C) 2021 Rain */

/* This file is part of Cunix. */

/* 
  Cunix is free software: you can redistribute it and/or modify 
  it under the terms of the GNU General Public License as published by 
  the Free Software Foundation, either version 3 of the License, or 
  (at your option) and later version. 
*/

/*
  Cunix is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
  GNU General Public License for more details. 
*/

/*
  You should have received a copy of the GNU General Public License 
   along with Cunix. If not, see <https://www.gnu.org/licenses/>.  
*/




#define ASSEMBLY
#include <modules/tty.h>



.text
.align 8



.globl tty_init

tty_init:
	pushq %rsi
	pushq %rdi

	/* set cursor position */
	movw $0x0000, %di
	call write_cursor

	popq %rdi
	popq %rsi

	ret
	

.globl putc

putc:
	pushq %rdi

	/* character is in EDI */
	movl %edi, %eax

	/* rdi = *framebuffer */
	movq framebuffer(%rip), %rdi
	movb $0x0f, %ah

	cld
	stosw

	movq %rdi, framebuffer(%rip)
	
	/* return 0 */
	xorq %rax, %rax

	popq %rdi
	ret


.data
.align 8

.globl framebuffer
framebuffer: .quad 0x00000000000b8000


