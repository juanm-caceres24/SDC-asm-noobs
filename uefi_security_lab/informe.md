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

> [!IMPORTANT]
> Screenshot de QEMU UEFI startup aqui

#### Exploración de Dispositivos (Handles y Protocolos)

UEFI no usa letras de unidad fijas (como C:). Mantiene una base de datos de "Handles" (identificadores) que agrupan "Protocolos" (interfaces de software como SIMPLE_FILE_SYSTEM).

Podemos utilizar comandos dentro de la Shell de UEFI para explorar estos handles y protocolos.

Con `map` mostramos una lista de todos los dispositivos de almacenamiento y sistemas de archivos que la UEFI ha detectado. Es el equivalente a abrir "Este equipo" en Windows para ver qué discos o pendrives están conectados.

> [!IMPORTANT]
> Screenshot de map aqui

Aqui solo podemos visualizar una entrada `BLK0` (Block Device 0) que es un dispositivo de hardware en bruto, estimamos el chip de memoria flash virtual donde reside la UEFI (el archivo OVMF.fd).

Esto es porque el comando que utilizamos para inicializar QEMU le dio memoria RAM (-m 512) y una placa madre con UEFI (-bios) pero no un disco duro ni un pendrive.

`FS0` (File System 0) dsolo aparece cuando la UEFI detecta un dispositivo que tiene un sistema de archivos que puede leer (casi siempre FAT32). Como no hay ningún disco conectado, no hay ningún sistema de archivos para leer.

Esto lo podemos solucionar fabricando un disco duro en blanco, formateandolo con FAT32, y conectandolo en la ejecucion de QEMU.

```bash
dd if=/dev/zero of=disk.img bs=1M count=64
mkfs.vfat disk.img
qemu-system-x86_64 -m 512 -bios /usr/share/ovmf/OVMF.fd -drive format=raw,file=disk.img -net none
```

> [!IMPORTANT]
> Screenshot de map con FS0 aqui

Con el disco adicionado, conseguimos observar el sistema de archivos `FS0`, donde ingresando el nombre del handler seguido de `:` conseguimos entrar a el.

> [!IMPORTANT]
> Screenshot de ingresar a FS0 aqui

Luego podemos ejecutar `ls` para visualizar el contenido, donde observamos solo un archivo presente de 10549 bytes.

> [!IMPORTANT]
> Screenshot de ls aqui

Este es el archivo `NvVars`, un documento generado de forma automática por el firmware UEFI (OVMF) durante el proceso de arranque que sirve como almacenamiento de emergencia para guardar las variables y configuraciones del sistema ya que el firmware se cargó en modo de solo lectura y necesita un espacio donde escribir esa información.

Dentro de UEFI podemos ejecutar `dh -b` para realizar un "Dump Handle" que imprime en pantalla información técnica sobre todos los handles y protocolos activos en el sistema. 
El `-b` le dice a la consola que haga una pausa cada vez que se llene la pantalla para scrollear el contenido.

> [!IMPORTANT]
> Screenshot de dh -b aqui

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

> [!IMPORTANT]
> Screenshot de dmpstore aqui

Con el comando `set TestSeguridad "Hola UEFI"` podemos crear una variable de entorno persistente en NVRAM llamada TestSeguridad con el valor "Hola UEFI". 
Al ejecutar el comando `set` que muestra la lista de variables del sistema podemos visualizarla.

> [!IMPORTANT]
> Screenshot de set -v aqui

> [!NOTE]
> El comando `set -v` es equivalente a realizar `set`.  
> El modificador `-v` solo impacta en la creacion de variables para tornarlas volatiles.

> **Pregunta de Razonamiento:**  
> Observando las variables Boot#### y BootOrder  
> ¿Cómo determina el Boot Manager la secuencia de arranque?

El Boot Manager lee BootOrder para saber en qué orden debe buscar, y luego consulta las variables Boot#### individuales para saber qué archivo ejecutar y dónde encontrarlo en el hardware.

Podemos ejecutar `dmpstore` para visualizar el contenido de las variables.

> [!IMPORTANT]
> Screenshot de dmpstore aqui

Vemos como la variable BootOrder en Little-Endian tiene como primera opcion de boot a Boot0000, seguido de 0001, 0002 y 0003.

Luego podemos ver a la derecha de cada variable Boot#### un indicio de que representan.

> [!IMPORTANT]
> Screenshot de dmpstore aqui

#### Footprinting de Memoria y Hardware

Con el comando `memmap` podemos observar el Mapa de Memoria de UEFI, esencialmente viendo cómo está distribuida físicamente la memoria RAM en determinado momento.

La UEFI no trata a la RAM como un solo bloque gigante, sino que la divide en secciones y le asigna un "Tipo" y permisos a cada una.

Al ejecutar el comando observamos una tabla con columnas que muestran la dirección de inicio, la dirección de fin y el tipo de memoria.

> [!IMPORTANT]
> Screenshot de memmap aqui

Con el comando `pci` listamos los dispositivos PCI. El bus PCI  es la "columna vertebral" del hardware de la placa madre. 

Este comando lista todos los componentes físicos conectados a ella (tarjetas de video, controladores de disco SATA/NVMe, placas de red, puertos USB).

> [!IMPORTANT]
> Screenshot de pci aqui

Aqui vemos una lista organizada por Bus, Dispositivo y Función (B/D/F). Por cada elemento vemos su Vendor ID y su Device ID.

Con el comando `drivers` podemos ver los controladores UEFI.

Así como Windows tiene drivers la UEFI tiene sus propios controladores en formato DXE (Driver Execution Environment) que le enseñan al firmware cómo usar el mouse, cómo leer un disco FAT32 o cómo dibujar gráficos básicos en la pantalla.

Al ejecutar el comando observamos un listado con un número de Handle, la versión del driver, el tipo y el nombre (ej. FAT File System Driver, Qemu Video Driver).

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

...

### Ejecución en Hardware Físico (Bare Metal)

...

### Referencias

> [UEFI](https://uefi.org/specs/UEFI/2.10/index.html)

> [UEFI Shell](https://uefi.org/sites/default/files/resources/UEFI_Shell_2_2.pdf)
