# Trabajo Practico N°3

## Calculadora de Indices

**Materia:** Sistemas de Computacion  
**Grupo:** asm_noobs  
**Integrantes:** [Fabian Nicolas Hidalgo] · [Juan Manuel Caceres] · [Agustin Alvarez]  
**Repositorio:** [Github](https://github.com/Nick07242000/SDC-asm-noobs/blob/main/TP_3)

---

### Desafio: BIOS, UEFI y Coreboot

#### ¿Qué es UEFI? 

UEFI, o Unified Extensible Firmware Interface segun sus siglas, es el sucesor moderno del BIOS. 

Es el "primer software" que se ejecuta cuando se enciende la computadora y actua como el puente principal entre el hardware y el sistema operativo.

A diferencia del BIOS tradicional la UEFI es practicamente un sistema operativo en miniatura con capacidades mucho mas avanzadas. Entre ellas mencionamos:

- Capacidad de disco: soporta particiones de disco mayores a 2.2 TB gracias al estandar GPT.
- Velocidad: permite un inicio del sistema mucho mas rapido.
- Interfaz: soporta el uso del mouse y graficos en alta resolucion.
- Seguridad: incluye Secure Boot que evita que se cargue software malicioso o controladores no firmados durante el arranque.

UEFI ademas expone una API de servicios (Boot Services y Runtime Services) accesibles a través de punteros a funciones en estructuras C estandar.

#### ¿Como se usa?

La UEFI puede utilizarse de forma interactiva para configurar como se comporta el hardware del sistema.

La forma clasica de acceder a ella es presionar una tecla específica (como F2, F12, Del o Esc) justo después de presionar el boton de encendido.

Una vez dentro podemos realizar diversas configuraciones, como cambiar el orden de arranque para instalar un sistema operativo desde un USB, ajustar las velocidades del procesador o la memoria RAM o revisar la temperatura de la CPU y la velocidad de los ventiladores en tiempo real.

#### Funciones UEFI

Una funcionalidad que puede ser explotada es la de escribir aplicaciones que corran directamente en el entorno UEFI antes de que cargue el sistema operativo. 
Esto se hace a través de servicios de arranque o servicios de tiempo de ejecucion.

Para escribir y ejecutar un programa en UEFI generalmente se utiliza el lenguaje C y un entorno de desarrollo. 
Los programas UEFI se ejecutan de forma independiente antes de que cargue el sistema operativo.

Una funcion basica que podemos llamar es `GetTime` de los Runtime Services para mostrar la fecha y la hora del sistema:
> Returns the current time and date information, and the time-keeping capabilities of the hardware platform.

Para esto se genera un programa en C de la forma:

```C
#include <Uefi.h>
#include <Library/UefiLib.h>

// entrypoint de la app UEFI
EFI_STATUS
EFIAPI
UefiMain (IN EFI_HANDLE ImageHandle, IN EFI_SYSTEM_TABLE *SystemTable)
{
  EFI_TIME Time;

  // llamamos a la funcion desde los runtime services
  SystemTable->RuntimeServices->GetTime(&Time, NULL);

  return EFI_SUCCESS;
}
```

Aqui encontramos los siguientes componentes del programa:
- `UefiMain`: Es el equivalente al `main()` en un programa C normal. Es lo primero que se ejecuta.
- `SystemTable`: Es el parametro mas importante. Es un puntero gigante que la UEFI le pasa al programa. Contiene todas las funciones necesarias para interactuar con el hardware.
- `EFI_TIME Time`: Esta es una estructura predefinida por UEFI que contiene espacios para el año, mes, día, hora, etc.

El contenido de Time entonces nos queda disponible dentro del programa para realizar lo que precisemos, obtenido directamente del hardware del sistema.

Este programa debe ser compilado con un entorno de desarrollo con la extension `.efi`, y luego este puede ser ejecutado desde un USB o una VM.

---

### Desafio: Linker y Hello World Bare-Metal

...

---

### Desafio: Modo Protegido

...

---

### Depuracion con GDB + QEMU

...

---

### Referencias

> ...
