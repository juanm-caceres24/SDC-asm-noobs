.code16                     # Directiva para el ensamblador: generar codigo maquina de 16 bits (Modo Real).
    mov $msg, %si           # Carga la direccion de memoria donde esta el texto (etiqueta 'msg') en el registro SI (Source Index).
    mov $0x0E, %ah          # Carga el valor 0x0E en el registro AH. Es el codigo de la funcion BIOS para "Teletype output" (imprimir caracter).

loop:                       # Etiqueta que marca el inicio del bucle de impresion.
    lodsb                   # Carga el byte al que apunta el registro SI en el registro AL, y automaticamente incrementa SI al siguiente byte.
    or %al, %al             # Operacion logica OR entre AL y si mismo. No cambia el valor de AL, pero sirve para actualizar las banderas del procesador.
    jz halt                 # Salta (Jump if Zero) a la etiqueta 'halt' si la operacion anterior dio 0 (es decir, si el caracter actual es el terminador nulo).
    int $0x10               # Ejecuta la interrupcion 0x10 de la BIOS. Como AH tiene 0x0E, la BIOS sabe que debe imprimir en pantalla el caracter alojado en AL.
    jmp loop                # Salto incondicional de vuelta a 'loop' para continuar con la siguiente letra.

halt:                       # Etiqueta para el final del programa.
    hlt                     # Instruccion Halt: detiene el procesador hasta que ocurra una interrupcion por hardware (ahorra energia y evita ejecutar basura de la RAM).

msg:                        # Etiqueta que le da un nombre a la posicion de memoria de nuestro texto.
    .asciz "Hello, World!"  # Directiva que inserta los caracteres en memoria y les anade automaticamente un byte 0x00 al final (null-terminated string).
