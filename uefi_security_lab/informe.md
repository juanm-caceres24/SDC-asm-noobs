# Trabajo Practico N°3A

## Uefi Security

**Materia:** Sistemas de Computacion  
**Grupo:** asm_noobs  
**Integrantes:** [Fabian Nicolas Hidalgo] · [Juan Manuel Caceres] · [Agustin Alvarez]  
**Repositorio:** [Github](https://github.com/Nick07242000/SDC-asm-noobs/blob/main/uefi_security_lab)

---

### Exploración del entorno UEFI y la Shell

**Objetivo:** Explorar cómo UEFI abstrae el hardware y gestiona la configuración antes de la carga del sistema operativo.

#### Arranque en el entorno virtual

A diferencia del BIOS Legacy que simplemente leía el primer sector de un disco (MBR), UEFI es un entorno completo con su propio gestor de memoria, red y consola.

Utilizamos QEMU para iniciar una máquina virtual de arquitectura de 64 bits, configurada con 512 MB de memoria RAM, arranque mediante firmware UEFI y sin ninguna conexión a la red.

```bash
qemu-system-x86_64 -m 512 -bios /usr/share/ovmf/OVMF.fd -net none
```

- qemu-system-x86_64: arquitectura de hardware x86 de 64 bits.
- -m 512: Asigna 512 megabytes de memoria RAM a esta máquina virtual.
- -bios /usr/share/ovmf/OVMF.fd: Cambia el firmware de arranque por defecto usando OVMF.fd en lugar de BIOS. 
- -net none: Deshabilita por completo el hardware de red, VM totalmente desconectada de internet y de red local.

> [!NOTE]
> OVMF (Open Virtual Machine Firmware) es una implementación de código abierto que permite a la máquina virtual arrancar usando UEFI.

Esta combinación de parámetros nos da un entorno ligero, de arranque rápido y completamente aislado por seguridad. 
Como no se especifica ningún disco duro o imagen ISO, la máquina enciende en la consola interactiva de UEFI (la UEFI Shell).

<img width="1042" height="925" alt="Screenshot from 2026-05-01 14-38-20" src="https://github.com/user-attachments/assets/01fd327d-6d4e-45ab-bbc2-a1337e9c9137" />

#### Exploración de Dispositivos (Handles y Protocolos)

UEFI no usa letras de unidad fijas (como C:). Mantiene una base de datos de "Handles" (identificadores) que agrupan "Protocolos" (interfaces de software como SIMPLE_FILE_SYSTEM).

Podemos utilizar comandos dentro de la Shell de UEFI para explorar estos handles y protocolos.

Con `map` mostramos una lista de todos los dispositivos de almacenamiento y sistemas de archivos que la UEFI ha detectado. Es el equivalente a abrir "Este equipo" en Windows para ver qué discos o pendrives están conectados.

<img width="647" height="307" alt="Screenshot from 2026-05-01 15-54-16" src="https://github.com/user-attachments/assets/3c434b8f-e456-408c-988b-b67075606b80" />

Aqui solo podemos visualizar una entrada `BLK0` (Block Device 0) que es un dispositivo de hardware en bruto, estimamos el chip de memoria flash virtual donde reside la UEFI (el archivo OVMF.fd).

Esto es porque el comando que utilizamos para inicializar QEMU le dio memoria RAM (-m 512) y una placa madre con UEFI (-bios) pero no un disco duro ni un pendrive.

`FS0` (File System 0) dsolo aparece cuando la UEFI detecta un dispositivo que tiene un sistema de archivos que puede leer (casi siempre FAT32). Como no hay ningún disco conectado, no hay ningún sistema de archivos para leer.

Esto lo podemos solucionar fabricando un disco duro en blanco, formateandolo con FAT32, y conectandolo en la ejecucion de QEMU.

```bash
dd if=/dev/zero of=disk.img bs=1M count=64
mkfs.vfat disk.img
qemu-system-x86_64 -m 512 -bios /usr/share/ovmf/OVMF.fd -drive format=raw,file=disk.img -net none
```

<img width="1324" height="973" alt="Screenshot from 2026-05-01 15-18-31" src="https://github.com/user-attachments/assets/87729c3f-a6bf-40d0-8e59-6925c1c43ba4" />

Con el disco adicionado, conseguimos observar el sistema de archivos `FS0`, donde ingresando el nombre del handler seguido de `:` conseguimos entrar a el.

<img width="610" height="355" alt="Screenshot from 2026-05-01 15-22-12" src="https://github.com/user-attachments/assets/40041ae4-891c-4f69-b708-78e8c10e4c31" />

Luego podemos ejecutar `ls` para visualizar el contenido, donde observamos solo un archivo presente de 10k bytes.

<img width="634" height="363" alt="Screenshot from 2026-05-01 18-24-27" src="https://github.com/user-attachments/assets/b7e27755-a699-4dd3-aef3-f93f6405467a" />

Este es el archivo `NvVars`, un documento generado de forma automática por el firmware UEFI (OVMF) durante el proceso de arranque que sirve como almacenamiento de emergencia para guardar las variables y configuraciones del sistema ya que el firmware se cargó en modo de solo lectura y necesita un espacio donde escribir esa información.

Dentro de UEFI podemos ejecutar `dh -b` para realizar un "Dump Handle" que imprime en pantalla información técnica sobre todos los handles y protocolos activos en el sistema. 
El `-b` le dice a la consola que haga una pausa cada vez que se llene la pantalla para scrollear el contenido.

<img width="702" height="510" alt="Screenshot from 2026-05-01 15-51-40" src="https://github.com/user-attachments/assets/2e00556d-bbd2-491f-9089-fdea4c45e9d5" />

> **Pregunta de Razonamiento:**  
> Al ejecutar el comando map y dh, vemos protocolos e identificadores en lugar de puertos de hardware fijos.  
> ¿Cuál es la ventaja de seguridad y compatibilidad de este modelo frente al antiguo BIOS?

En el BIOS tradicional el software de arranque tenía que hablar directamente con los puertos de hardware físicos o usar interrupciones fijas de la placa madre.
Si la tecnología cambiaba el código a bajo nivel dejaba de funcionar porque los puertos físicos eran distintos.

Con el modelo UEFI se crea una capa de abstracción. Al gestor de arranque no le importa cómo está cableado el hardware internamente, UEFI se encarga de la traducción.
Esto hace que el entorno sea completamente modular y a prueba de futuro.

Ademas como BIOS dependía de ubicaciones físicas predecibles y sin restricciones era un blanco perfecto para atacantes. 
Un malware o bootkit sobrescribía esas direcciones físicas de memoria fijas y tomaba el control del sistema antes de que el antivirus o el propio Windows pudieran arrancar.

Con el modelo UEFI al forzar a que toda interacción pase a través de Protocolos gestionados por el firmware, se elimina el acceso directo y caótico al hardware. 
Ahora el firmware actúa como un guardia de seguridad. Esta arquitectura basada en interfaces estructuradas es la que hace posible el Secure Boot.

#### Análisis de Variables Globales (NVRAM)

La fase BDS (Boot Device Selection) decide qué cargar basándose en variables no volátiles.

A diferencia del viejo BIOS, que guardaba su configuración en un chip CMOS muy limitado, UEFI utiliza un sistema avanzado de variables para almacenar configuraciones del sistema, claves de seguridad y órdenes de arranque en NVRAM.

Con el comando `dmpstore` podemos imprimir en pantalla todo el contenido de la NVRAM de la UEFI. 
Aquí es donde el firmware guarda datos que deben sobrevivir a los reinicios, como el orden de booteo, las configuraciones del hardware y las bases de datos de claves criptográficas del Secure Boot.

<img width="673" height="517" alt="Screenshot from 2026-05-01 16-28-37" src="https://github.com/user-attachments/assets/c9698e0a-a33e-4dc5-8ade-813c811e0c02" />

Con el comando `set TestSeguridad "Hola UEFI"` podemos crear una variable de entorno persistente en NVRAM llamada TestSeguridad con el valor "Hola UEFI". 
Al ejecutar el comando `set` que muestra la lista de variables del sistema podemos visualizarla.

<img width="673" height="512" alt="Screenshot from 2026-05-01 16-33-15" src="https://github.com/user-attachments/assets/8e3f74c0-1059-4f1d-b76b-124b5620c8e8" />

> [!NOTE]
> El comando `set -v` es equivalente a realizar `set`.  
> El modificador `-v` solo impacta en la creacion de variables para tornarlas volatiles.

> **Pregunta de Razonamiento:**  
> Observando las variables Boot#### y BootOrder  
> ¿Cómo determina el Boot Manager la secuencia de arranque?

El Boot Manager lee BootOrder para saber en qué orden debe buscar, y luego consulta las variables Boot#### individuales para saber qué archivo ejecutar y dónde encontrarlo en el hardware.

Podemos ejecutar `dmpstore` para visualizar el contenido de las variables.

<img width="613" height="273" alt="Screenshot from 2026-05-01 17-34-47" src="https://github.com/user-attachments/assets/7990dca4-ede0-4ea8-a452-8a51cd535021" />

Vemos como la variable BootOrder en Little-Endian tiene como primera opcion de boot a Boot0000, seguido de 0001, 0002 y 0003.

Luego podemos ver a la derecha de cada variable Boot#### un indicio de que representan.

<img width="672" height="379" alt="Screenshot from 2026-05-01 17-35-15" src="https://github.com/user-attachments/assets/a769a279-c946-4fbd-b208-8b7896637d30" />
<img width="683" height="505" alt="Screenshot from 2026-05-01 17-43-14" src="https://github.com/user-attachments/assets/b817b5db-e359-4bf2-b41b-c064805ad6c1" />

#### Footprinting de Memoria y Hardware

Con el comando `memmap` podemos observar el Mapa de Memoria de UEFI, esencialmente viendo cómo está distribuida físicamente la memoria RAM en determinado momento.

La UEFI no trata a la RAM como un solo bloque gigante, sino que la divide en secciones y le asigna un "Tipo" y permisos a cada una.

Al ejecutar el comando observamos una tabla con columnas que muestran la dirección de inicio, la dirección de fin y el tipo de memoria.

<img width="683" height="508" alt="Screenshot from 2026-05-01 17-47-04" src="https://github.com/user-attachments/assets/b7868ab9-6b11-4e78-8017-d03c91da0c09" />

Con el comando `pci` listamos los dispositivos PCI. El bus PCI  es la "columna vertebral" del hardware de la placa madre. 

Este comando lista todos los componentes físicos conectados a ella (tarjetas de video, controladores de disco SATA/NVMe, placas de red, puertos USB).

<img width="683" height="508" alt="Screenshot from 2026-05-01 17-50-22" src="https://github.com/user-attachments/assets/9480dc1a-12da-4b75-848a-f8bfa1a3db8d" />

Aqui vemos una lista organizada por Bus, Dispositivo y Función (B/D/F). Por cada elemento vemos su Vendor ID y su Device ID.

Con el comando `drivers` podemos ver los controladores UEFI.

Así como Windows tiene drivers la UEFI tiene sus propios controladores en formato DXE (Driver Execution Environment) que le enseñan al firmware cómo usar el mouse, cómo leer un disco FAT32 o cómo dibujar gráficos básicos en la pantalla.

Al ejecutar el comando observamos un listado con un número de Handle, la versión del driver, el tipo y el nombre (ej. FAT File System Driver, Qemu Video Driver).

<img width="683" height="508" alt="Screenshot from 2026-05-01 17-52-59" src="https://github.com/user-attachments/assets/a5b7c281-cdbe-40c2-a49f-936fba625c40" />

> **Pregunta de Razonamiento:**  
> En el mapa de memoria (memmap), existen regiones marcadas como RuntimeServicesCode.  
> ¿Por qué estas áreas son un objetivo principal para los desarrolladores de malware (Bootkits)?

Las regiones marcadas como RuntimeServicesCode son el objetivo principal de los Bootkits porque es la única memoria de la UEFI que sobrevive a la carga del Sistema Operativo.  
Si un malware logra inyectarse en esta área, seguirá vivo y ejecutándose en la RAM de forma completamente invisible incluso después de que Windows o Linux hayan arrancado.

El sistema operativo necesita hacerle preguntas a la placa madre despues del boot. Para esto, la UEFI carga ciertas funciones en RuntimeServicesCode.
Cuando la UEFI le entrega el mapa de memoria a Windows, indica la porción de la memoria que es RuntimeServicesCode, y Windows respeta esta seccion y la deja intacta.

Si un desarrollador de malware inyecta su virus dentro de un área de RuntimeServicesCode, el código malicioso cruza la frontera entre el firmware y el sistema operativo sin ser destruido y puede ser ejecutado con privilegios más altos que el propio Kernel de Windows (Ring -2). Desde allí, puede parchear el sistema operativo en tiempo real, robar contraseñas en memoria o desactivar medidas de seguridad del OS.

Los antivirus convencionales escanean los procesos del sistema operativo y los discos duros. Generalmente no tienen permisos ni capacidad para auditar y analizar el código que se ejecuta en las regiones de memoria de los Runtime Services del firmware, haciendo que el malware sea virtualmente indetectable.

### Desarrollo, compilación y análisis de seguridad

#### Desarrollo de Aplicación

**aplicacion.c**
```C
#include <efi.h>
#include <efilib.h>

EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) 
{
    InitializeLib(ImageHandle, SystemTable);
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"Iniciando analisis de seguridad...\r\n");
    // Inyección de un software breakpoint (INT3)
    unsigned char code[] = { 0xCC };
    if (code[0] == 0xCC) 
    {
        SystemTable->ConOut->OutputString(SystemTable->ConOut, L"Breakpoint estatico alcanzado.\r\n");
    }
    return EFI_SUCCESS;
}
```
Minima explicación de `aplicacion.c`: 

Este código es una aplicación UEFI, que corre en el entorno de firmware.

Está usando las librerías de GNU-EFI:
- `efi.h`: define las estructuras base de UEFI (tipos como EFI_STATUS, EFI_HANDLE, EFI_SYSTEM_TABLE).
- `efilib.h`: funciones auxiliares (como InitializeLib) que simplifican el uso del entorno EFI.

El punto de entrada es `efi_main()`, que es el equivalente al main() en programas normales, pero para UEFI.

¿Qué se está queriendo hacer?

- Muestra un mensaje inicial: *Iniciando analisis de seguridad...*
- Define un byte con valor `0xCC`.
- Verifica ese valor e imprime otro mensaje si coincide: *Breakpoint estatico alcanzado.*

> **Pregunta de Razonamiento:**  
> ¿Por qué utilizamos SystemTable->ConOut->OutputString en lugar de la función printf de C?

Utilizamos `SystemTable->ConOut->OutputString` porque la aplicación se ejecuta en un entorno UEFI, donde no existe un sistema operativo ni la infraestructura de runtime de C.
La función `printf` pertenece a la librería estándar de C y depende de mecanismos de entrada/salida como `stdout` y `syscalls`, que no están disponibles en este entorno.
En su lugar, UEFI provee sus propios protocolos de I/O, como `ConOut`, que permiten interactuar directamente con la consola del firmware.

#### Compilación a Formato PE/COFF

Comandos:
```bash
# 1. Compilar a código objeto
gcc -I/usr/include/efi -I/usr/include/efi/x86_64 -I/usr/include/efi/protocol -fpic -ffreestanding
-fno-stack-protector -fno-strict-aliasing -fshort-wchar -mno-red-zone
-maccumulate-outgoing-args -Wall -c -o aplicacion.o aplicacion.c
# 2. Linkear (generar .so intermedio)
ld -shared -Bsymbolic -L/usr/lib -L/usr/lib/efi -T /usr/lib/elf_x86_64_efi.lds
/usr/lib/crt0-efi-x86_64.o aplicacion.o -o aplicacion.so -lefi -lgnuefi
# 3. Convertir a ejecutable EFI (PE/COFF)
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc
--target=efi-app-x86_64 aplicacion.so aplicacion.efi
```
**Breve descripción de los flags que intervienen:**

**Compilación:**

- Los includes `-I/..` agregan paths de los headers de GNU-EFI
- `-ffreestanding` indica que no hay OS
- `-fpic` genera código compatible con firmware (**Position Independent Code**),necesario porque UEFI puede cargar la imagen en distintas direcciones.
- `-fno-stack-protector` desactiva protección de stack.
- `-fno-strict-aliasing` evita optimizaciones que pueden romper código de bajo nivel
- `-fshort-wchar` define el ancho de caracteres en 2 bytes (UTF-16)
- `mno-red-zone` desactiva la red zone de x86_64
- `maccumulate-outgoing-args` asegura layout estable de argumentos en stack

**Linkeo:**
- `-shared` genera un binario tipo shared object (.so)
- `-Bsymbolic` resuelve símbolos dentro del propio binario, y evita problemas de relocación en firmware
- `L...` paths donde buscar librerías (libefi, libgnuefi)

- `-T elf_x86_64_efi.lds` linker script, UEFI necesita un layout específico, organiza el binario final en memoria (define secciones compatible con UEFI)
    > Sin este script, el binario tendría un layout ELF estándar no compatible con UEFI y fallaría al cargarse.

- `/usr/lib/crt0-efi-x86_64.o` runtime inicial (entry point real antes de efi_main)
    > Es el puente entre el firmware UEFI y el código C.

- `-lefi` Librería base de EFI ( **EFI_STATUS, EFI_HANDLE,  EFI_SYSTEM_TABLE** )
- `-lgnuefi` Librería de utilidades de GNU-EFI. ( **InitializeLib()** )

**Conversión a formato EFI**

- `objcopy` convierte el binario ELF (.so) a formato PE/COFF (.efi)
- `-j <sección>` incluye únicamente las secciones especificadas en el binario final
- `--target=efi-app-x86_64` define el formato de salida como aplicación EFI de 64 bits (PE/COFF)

**Resumen:**
```text
C
↓ (gcc)
ELF objeto (.o)
↓ (ld)
ELF compartido (.so)
↓ (objcopy)
PE/COFF (.efi)  ← lo que ejecuta UEFI
```

#### Análisis de Metadatos y Decompilación

Comandos:
```bash
file aplicacion.efi
readelf -h aplicacion.efi
ghidra
```

Al ejecutar `file aplicacion.efi` podemos ver el tipo de archivo:

----------IMG file_aplicacion.efi----------

Al ejecutar `readelf -h aplicacion.efi` vemos que genera un error:

----------IMG readelf----------

Esto se debe a que el comando `readelf -h` intenta leer el header como si `aplicacion.efi` fuese un archivo ELF, por lo tanto el error es correcto, ya que el formato que le desiganmos al archivo en el paso anterior es de `PE/COFF`

Luego de ejecutar `ghidra` necesitamos generar un proyecto e importar el archivo `aplicacion.efi` para poder hacer ingenieria inversa del mismo.

----------IMG import_aplicacion.efi----------

----------IMG ghidra----------

> **Pregunta de Razonamiento:**  
> En el pseudocódigo de Ghidra, la condición 0xCC suele aparecer como -52. ¿A qué se debe este fenómeno y por qué importa en ciberseguridad?

El valor 0xCC aparece como -52 debido a la interpretación de tipos con signo. En sistemas donde char es signed, 0xCC (204 decimal) se interpreta como -52 al representarse en **complemento a dos**.
> El complemento a dos es una representación binaria de enteros con signo en la que los números negativos se obtienen invirtiendo los bits del valor positivo y sumando uno.

En ciberseguridad, esta distinción es crítica, ya que herramientas de análisis como decompiladores pueden representar los mismos datos de formas distintas, lo que puede llevar a interpretaciones erróneas del comportamiento del programa. Además, técnicas de evasión utilizadas en malware pueden explotar estas diferencias para ocultar instrucciones o dificultar el análisis.

#### Análisis función *efi_main()*

> [!NOTE]
> En el panel izquierdo en la seccion `Functions` se pueden filtral las funciones, y buscar `efi_main`.

Aca se puede ver seccion del `efi_main`:

----------IMG seccion_efi_main----------

En este caso, el valor 0xCC no aparece como -52 en el pseudocódigo de Ghidra porque la condición fue optimizada por el compilador al ser constante, eliminando el if. Sin embargo, el valor puede observarse en el código assembly como 0xCC, donde se realiza la comparación correspondiente.

----------IMG 0xcc----------

### Ejecución en Hardware Físico (Bare Metal)

...

### Referencias

> [UEFI](https://uefi.org/specs/UEFI/2.10/index.html)

> [UEFI Shell](https://uefi.org/sites/default/files/resources/UEFI_Shell_2_2.pdf)
