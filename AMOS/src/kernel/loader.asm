;     AAA    M M    OOO    SSSS
;    A   A  M M M  O   O  S 
;    AAAAA  M M M  O   O   SSS
;    A   A  M   M  O   O      S
;    A   A  M   M   OOO   SSSS 
;
;    Author:  Stephen Fewer
;    Contact: steve [AT] harmonysecurity [DOT] com
;    Web:     http://amos.harmonysecurity.com/
;    License: GNU General Public License (GPL)

BITS 32

KERNEL_VMA				equ 0xC0001000
KERNEL_LMA				equ 0x00101000

KERNEL_DATA_SEL			equ	0x10

MULTIBOOT_PAGE_ALIGN	equ 1<<0
MULTIBOOT_MEMORY_INFO	equ 1<<1
MULTIBOOT_AOUT_KLUDGE	equ 1<<16
MULTIBOOT_HEADER_MAGIC	equ 0x1BADB002
MULTIBOOT_HEADER_FLAGS	equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO
MULTIBOOT_CHECKSUM		equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

EXTERN text, kernel, setup, data, bss, _end, _kernel_main

EXTERN _interrupt_dispatcher, _scheduler_switch

EXTERN _current_esp, _current_cr3

GLOBAL _VGDTR

GLOBAL _setup
GLOBAL _start

GLOBAL _isr00
GLOBAL _isr01
GLOBAL _isr02
GLOBAL _isr03
GLOBAL _isr04
GLOBAL _isr05
GLOBAL _isr06
GLOBAL _isr07
GLOBAL _isr08
GLOBAL _isr09
GLOBAL _isr10
GLOBAL _isr11
GLOBAL _isr12
GLOBAL _isr13
GLOBAL _isr14
GLOBAL _isr15
GLOBAL _isr16
GLOBAL _isr17
GLOBAL _isr18
GLOBAL _isr19
GLOBAL _isr20
GLOBAL _isr21
GLOBAL _isr22
GLOBAL _isr23
GLOBAL _isr24
GLOBAL _isr25
GLOBAL _isr26
GLOBAL _isr27
GLOBAL _isr28
GLOBAL _isr29
GLOBAL _isr30
GLOBAL _isr31

GLOBAL _irq00
GLOBAL _irq01
GLOBAL _irq02
GLOBAL _irq03
GLOBAL _irq04
GLOBAL _irq05
GLOBAL _irq06
GLOBAL _irq07
GLOBAL _irq08
GLOBAL _irq09
GLOBAL _irq10
GLOBAL _irq11
GLOBAL _irq12
GLOBAL _irq13
GLOBAL _irq14
GLOBAL _irq15

GLOBAL _disable_int
GLOBAL _disable_irqA
GLOBAL _disable_irqB

SECTION .setup

PAGE_DIRCTORY	equ	0x9C000
PAGE_TABLE_1	equ	0x9D000
PAGE_TABLE_2	equ	0x9E000
PRIV			equ	3

_setup:
	push ebx					; store the pointer to the Grub multi boot header for later
	mov eax, PAGE_TABLE_1		; create a page table that identity maps the first 4MB of mem
	mov ebx, 0x00000000 | PRIV	; starting address of physical memory
	call map
	mov eax, PAGE_TABLE_2		; create a page table that will map the kernel into the 3GB mark
	mov ebx, 0x00100000 | PRIV
	call map
	mov dword [PAGE_DIRCTORY], PAGE_TABLE_1 | PRIV			; store the first page table into the page directory
	mov dword [PAGE_DIRCTORY + 768*4], PAGE_TABLE_2 | PRIV	; store the second page table into the page directory entry 768 (3GB mark)
	mov eax, PAGE_DIRCTORY		; enable paging
	mov cr3, eax
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax
	pop ebx						; restore ebx with the pointer to the multi boot header
	jmp 0x08:KERNEL_VMA			; jump into the kenel at it virtual memory address
map:
	mov ecx, 1024				; loop 1024 times (number of entry's in a page table)
lmap:
	mov dword [eax], ebx		; move next entry (ebx) into the page table (eax)
	add eax, 4					; move forward to next entry in table
	add ebx, 4096				; move address forward by a page size
	loop lmap					; go again untill ecx == 0
	ret							; return to caller
	
ALIGN 4
boot:
    dd MULTIBOOT_HEADER_MAGIC
    dd MULTIBOOT_HEADER_FLAGS
    dd MULTIBOOT_CHECKSUM

SECTION .kernel

_start:
    mov esp, stack
    push dword 0
    popf

    xor eax, eax
    mov edi, bss
    mov ecx, _end
    sub ecx, edi
    shr ecx, 2
    rep stosd

	push ebx

    call _kernel_main
    hlt
    
isr_common_stub:
    pushad					; push all general purpose registers
    push ds					; push al the segments
    push es
    push fs
    push gs 
    mov ax, KERNEL_DATA_SEL	; set data segments for kernel
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    push esp				; push current stack pointer
    call _interrupt_dispatcher	; call out C interrupt_dispatcher() function
	add esp, 4				; clean up the previously pushed stack pointer
    pop gs					; pop al the segments
    pop fs
    pop es
    pop ds
    popad					; pop all general purpose registers
    add esp, 8				; clean up the two bytes we pushed on via the _isrXX routine
    iret					; iret back

_disable_int:
	iret

_disable_irqA:
	mov al, 0x20
	out 0x20, al
	iret

_disable_irqB:
	mov al, 0x20
	out 0xA0, al
	out 0x20, al
	iret

;  Divide By Zero
_isr00:
    push byte 0
    push byte 0
    jmp isr_common_stub

;  Debug
_isr01:
    push byte 0
    push byte 1
    jmp isr_common_stub

;  Non Maskable Interrupt
_isr02:
    push byte 0
    push byte 2
    jmp isr_common_stub

;  Int 3
_isr03:
    push byte 0
    push byte 3
    jmp isr_common_stub

;  INTO
_isr04:
    push byte 0
    push byte 4
    jmp isr_common_stub

;  Out of Bounds
_isr05:
    push byte 0
    push byte 5
    jmp isr_common_stub

;  Invalid Opcode
_isr06:
    push byte 0
    push byte 6
    jmp isr_common_stub

;  Co-processor Not Available
_isr07:
    push byte 0
    push byte 7
    jmp isr_common_stub

;  Double Fault
_isr08:
    push byte 8
    jmp isr_common_stub

;  Coprocessor Segment Overrun
_isr09:
    push byte 0
    push byte 9
    jmp isr_common_stub

; Bad TSS
_isr10:
    push byte 10
    jmp isr_common_stub

; Segment Not Present
_isr11:
    push byte 11
    jmp isr_common_stub

; Stack Fault
_isr12:
    push byte 12
    jmp isr_common_stub

; General Protection Fault
_isr13:
    push byte 13
    jmp isr_common_stub

; Page Fault
_isr14:
    push byte 14
    jmp isr_common_stub

; Reserved
_isr15:
    push byte 0
    push byte 15
    jmp isr_common_stub

; Floating Point
_isr16:
    push byte 0
    push byte 16
    jmp isr_common_stub

; Alignment Check
_isr17:
    push byte 0
    push byte 17
    jmp isr_common_stub

; Machine Check
_isr18:
    push byte 0
    push byte 18
    jmp isr_common_stub

; Reserved
_isr19:
    push byte 0
    push byte 19
    jmp isr_common_stub

; Reserved
_isr20:
    push byte 0
    push byte 20
    jmp isr_common_stub

; Reserved
_isr21:
    push byte 0
    push byte 21
    jmp isr_common_stub

; Reserved
_isr22:
    push byte 0
    push byte 22
    jmp isr_common_stub

; Reserved
_isr23:
    push byte 0
    push byte 23
    jmp isr_common_stub

; Reserved
_isr24:
    push byte 0
    push byte 24
    jmp isr_common_stub

; Reserved
_isr25:
    push byte 0
    push byte 25
    jmp isr_common_stub

; Reserved
_isr26:
    push byte 0
    push byte 26
    jmp isr_common_stub

; Reserved
_isr27:
    push byte 0
    push byte 27
    jmp isr_common_stub

; Reserved
_isr28:
    push byte 0
    push byte 28
    jmp isr_common_stub

; Reserved
_isr29:
    push byte 0
    push byte 29
    jmp isr_common_stub

; Reserved
_isr30:
    push byte 0
    push byte 30
    jmp isr_common_stub

; Reserved
_isr31:
    push byte 0
    push byte 31
    jmp isr_common_stub
	
_irq00:
    push byte 0					; we dont need these but push a dummy error code and int number so the PROCESS_STACK sructure fits properly
    push byte 32
    pushad						; push all general purpose registers
    push ds						; push al the segments
    push es
    push fs
    push gs  
    mov ax, KERNEL_DATA_SEL		; set data segments for kernel
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax  
	mov [_current_esp], esp		; save the current esp
    call _scheduler_switch		; call out C scheduler_switch() function
    mov eax, [_current_cr3]		; switch over to the tasks address space
    mov cr3, eax
	mov esp, [_current_esp]		; restore esp (possibly a new one)
	mov al, 0x20
	out 0x20, al
    pop gs						; pop al the segments
    pop fs
    pop es
    pop ds  
    popad						; pop all general purpose registers
    add esp, 8					; clear off the two bytes we pushed at the begining
    iret						; iret back

_irq01:
    push byte 0
    push byte 33
    jmp isr_common_stub

_irq02:
    push byte 0
    push byte 34
    jmp isr_common_stub

_irq03:
    push byte 0
    push byte 35
    jmp isr_common_stub

_irq04:
    push byte 0
    push byte 36
    jmp isr_common_stub

_irq05:
    push byte 0
    push byte 37
    jmp isr_common_stub

_irq06:
    push byte 0
    push byte 38
    jmp isr_common_stub

_irq07:
    push byte 0
    push byte 39
    jmp isr_common_stub

_irq08:
    push byte 0
    push byte 40
    jmp isr_common_stub

_irq09:
    push byte 0
    push byte 41
    jmp isr_common_stub

_irq10:
    push byte 0
    push byte 42
    jmp isr_common_stub

_irq11:
    push byte 0
    push byte 43
    jmp isr_common_stub

_irq12:
    push byte 0
    push byte 44
    jmp isr_common_stub

_irq13:
    push byte 0
    push byte 45
    jmp isr_common_stub

_irq14:
    push byte 0
    push byte 46
    jmp isr_common_stub

_irq15:
    push byte 0
    push byte 47
    jmp isr_common_stub
    
SECTION	.bss
ALIGN	16
RESB	4096
stack:
