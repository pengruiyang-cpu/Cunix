; Copyright (C) 2021 Rain

; This file is part of Cunix. 

; Cunix is free software: you can redistribute it and/or modify 
; it under the terms of the GNU General Public Licene and published by 
; the Free Software Foundation, either version 3 of the License, or 
; (at your option) any later version. 

; Cunix is distributed in the hope that it will be useful, 
; but WITHOUT ANY WARRANTY; without even the implied warranty of 
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
; GNU General Public License for more details. 

; You should have recceived a copy of the GNU General Public License 
; along with Cunix. If not, see <https://www.gnu.org/licenses/>. 




org 0x8000
align 8

jmp _start

CYLINDERS_READ equ 10
SECTORS_READ equ CYLINDERS_READ * 2 * 18
SIZE_READ equ SECTORS_READ * 512

%include "arch/x86/segment.inc"
%include "arch/x86/paging.inc"

bits 16

_start:	
	; enable A20 address 20 line
.open_a20:
	in al, 0x92
	or al, 0x02
	out 0x92, al

.to_protect_mode:
	cli
	lgdt [gdt32_descriptor]


	mov eax, cr0
	; set CR0.bit 1 (Protect-mode Enable)
	or eax, 1
	mov cr0, eax

	jmp dword code32:init_protect_mode


bits 32

init_protect_mode:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ss, ax
	mov esp, 0x00007c00

.copy_kernel:
	mov esi, 0x8200
	mov edi, 0x100000
	mov ecx, SIZE_READ

	call memcpy

.to_long_mode:
	; page map at 0x7000
	; set pagemap level-4
	mov dword [0x70000], 0x71000 | PAGE_USER
	mov dword [0x70004], 0x00000
	mov dword [0x70800], 0x70000 | PAGE_USER
	mov dword [0x70804], 0x00000

	; ...and, page directory pointer table
	mov dword [0x71000], 0x72000 | PAGE_USER
	mov dword [0x71008], 0x00000

	; then, page directory entry (2 MB size)
	mov dword [0x72000], 0x000000 | PAGE_KERNEL
	mov dword [0x72004], 0x000000

	mov dword [0x72008], 0x200000 | PAGE_KERNEL
	mov dword [0x7200c], 0x000000

	mov dword [0x72010], 0x400000 | PAGE_KERNEL
	mov dword [0x72014], 0x000000


	lgdt [gdt64_descriptor]

	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ss, ax
	mov esp, 0x00007c00

	mov eax, cr4
	bts eax, 5
	mov cr4, eax

	; page table
	mov eax, 0x70000
	mov cr3, eax

	; enable long-mode before paging
	mov ecx, 0xc0000080
	rdmsr

	bts eax, 8
	wrmsr

	mov eax, cr0
	or eax, 1
	bts eax, 31
	mov cr0, eax

	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	
	jmp code64:0x100000


memcpy:
	; if no this, loop will --ecx and ecx will be 0xffffffff. 
	cmp ecx, 0
	jne .copy

	ret

.copy:
	lodsb
	stosb

	loop .copy

	ret

gdt32:
	dd 0x00000000, 0x00000000

gdt32_code:
	dd 0x0000ffff, 0x00cf9a00

gdt32_data:
	dd 0x0000ffff, 0x00cf9200

gdt32_len equ $ - gdt32

gdt32_descriptor:
	dw gdt32_len - 1
	dd gdt32

code32 equ gdt32_code - gdt32
data32 equ gdt32_data - gdt32


gdt64:
	dq 0x0000000000000000

gdt64_code:
	dq 0x0020980000000000

gdt64_data:
	dq 0x0000920000000000

gdt64_len equ $ - gdt64

gdt64_descriptor:
	dw gdt64_len - 1
	dd gdt64

code64 equ gdt64_code - gdt64
data64 equ gdt64_data - gdt64


times 512 - ($ - $$) db 0x00

