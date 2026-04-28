.code16
.global _start

_start:
    cli                                 # deshabilitar interrupciones

    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %ss
    mov $0x7C00, %sp

    lgdt gdt_descriptor                 # cargar GDT

    mov %cr0, %eax                      # activar modo protegido (CR0.PE = 1)
    or $0x1, %eax
    mov %eax, %cr0

    ljmp $0x08, $protected_mode_entry   # salto lejano para limpiar pipeline

# GDT 
.align 8
gdt_start:
    .quad 0x0000000000000000     # descriptor nulo

    # descriptor código: base=0x00
    .word 0xFFFF                 # limit low
    .word 0x0000                 # base low
    .byte 0x00                   # base mid
    .byte 0x9A                   # access: code, exec/read
    .byte 0xCF                   # flags + limit high
    .byte 0x00                   # base high

    # descriptor datos: base=0x10
    .word 0xFFFF
    .word 0x0000
    .byte 0x10
    .byte 0x90                   # access: data, only_read
    .byte 0xCF
    .byte 0x00

gdt_end:

gdt_descriptor:
    .word gdt_end - gdt_start - 1
    .long gdt_start

# Modo protegido
.code32
protected_mode_entry:

    # cargar selectores
    mov $0x10, %ax       # selector de datos (2do descriptor)
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    # stack en modo protegido
    mov $0x90000, %ebp   # que no este cerca del Bootloader
    mov %ebp, %esp

    # write en segmento read-only
    movl $0x12345678, 0x10

loop:                    # Bucle infinito
    jmp loop
