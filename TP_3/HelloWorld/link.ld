SECTIONS
{
    /* Establece el "location counter" (contador de ubicacion actual) en la direccion fisica 0x7C00. */
    /* Es la direccion de memoria exacta donde la BIOS carga el sector de arranque. */
    . = 0x7C00;
    
    /* Define la seccion de salida '.text', que contendra nuestro codigo ejecutable. */
    .text :
    {
        /* Crea un simbolo llamado '__start' y le asigna la direccion actual (0x7C00). */
        /* Esto es extremadamente util para tener una referencia visual y depurar con GDB. */
        __start = .;
        
        /* Le indica al linker que tome todas las secciones '.text' de los archivos .o de entrada */
        /* y las pegue exactamente aqui, una tras otra. */
        *(.text)
        
        /* Mueve el location counter exactamente 510 bytes (0x1FE en hexadecimal) hacia adelante, */
        /* contando de manera relativa desde el inicio de esta misma seccion '.text'. */
        /* Todo el espacio vacio entre el final del codigo y este punto se rellena con ceros. */
        . = 0x1FE;
        
        /* Inserta un valor de 2 bytes (un "short"). Escribe la firma magica de booteo 0x55 0xAA. */
        /* Nota: Se escribe 0xAA55 por la arquitectura Little Endian de x86, que invierte los bytes. */
        SHORT(0xAA55)
    }
}
