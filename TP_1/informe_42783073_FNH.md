# Trabajo Practico N°1

## El Rendimiento de las Computadoras

### Relacion Tiempo y Frecuencia

> Dado un procesador al que se le pueda cambiar la frecuencia, ejecutamos un código que demore alrededor de 10 segundos.
> ¿Qué sucede con el tiempo del programa al duplicar (variar) la frecuencia ? 

...

---

### Benchmarks

> Armar una lista de benchmarks
> ¿Cuales les serían más útiles a cada uno?
> ¿Cuáles podrían llegar a medir mejor las tareas que ustedes realizan a diario?

...

> Pensar en las tareas que cada uno realiza a diario y escribir en una tabla de dos entradas las tareas y que benchmark la representa mejor.

|Tarea|Benchmark|
|---|---|
|1|1|
|2|2|
|3|3|
|4|4|
|5|5|

> ¿Cual es el rendimiento de estos procesadores para compilar el kernel?
> Intel Core i5-13600K (base)
> AMD Ryzen 9 5900X 12-Core

...

> ¿Cual es la aceleración cuando usamos un AMD Ryzen 9 7950X 16-Core?
> ¿Cual de ellos hace un uso más eficiente de la cantidad de núcleos que tiene?
> ¿Cuál es más eficiente en términos de costo (dinero y energía)?

...

---

### GNU GCC Profiling

#### _Habilitamos creacion de perfiles durante la compilacion_

Dado el codigo en C:

```c
#include<stdio.h>

void new_func1(void);

void func1(void)
{
    printf("\n Inside func1 \n");
    int i = 0;

    for(;i<0xffffffff;i++);
    new_func1();

    return;
}

static void func2(void)
{
    printf("\n Inside func2 \n");
    int i = 0;

    for(;i<0xffffffaa;i++);
    return;
}

int main(void)
{
    printf("\n Inside main()\n");
    int i = 0;

    for(;i<0xffffff;i++);
    func1();
    func2();

    return 0;
}
```

```c
#include<stdio.h>

void new_func1(void)
{
    printf("\n Inside new_func1()\n");
    int i = 0;

    for(;i<0xffffffee;i++);

    return;
}
```

Nos aseguramos que la generacion de perfiles este habilitada a la hora de compilacion agregando la opcion `-pg`en el paso de compilacion:

`gcc -Wall -pg test_gprof.c test_gprof_new.c -o test_gprof`

#### _Ejecutamos el codigo_

Procedemos a ejecutar el archivo binario producido para generar la informacion de perfiles:

`./test_gprof`

Al ejecutar el binario vemos como se genera un nuevo archivo llamado `gmon.out` en el directorio de trabajo actual.

#### _Ejecutamos gprof_

La herramienta se ejecuta con el nombre del ejecutable a analizar, y el archivo `gmon.out` producido anteriormente.

`gprof test_gprof gmon.out > analysis.txt`

Esto produce un archivo de analisis que contiene toda la informacion de perfil deseada `analysis.txt`.

#### _Interpretamos la informacion de perfil_

! INCLUIR SNIPPETS DE ARCHIVOS GENERADOS ACA

#### _Customizando el output con flags_

Podemos suprimir la impresion de funciones declaradas estaticamente (privadas) con `-a`

`gprof -a test_gprof gmon.out > analysis.txt`

! snippet de ejecucion

Podemos eliminar los textos detallados usando `-b`

`gprof -b test_gprof gmon.out > analysis.txt`

! snippet de ejecucion

Podemos imprimir solo el perfil plano usando `-p`

`gprof -p test_gprof gmon.out > analysis.txt`

! snippet de ejecucion

Podemos imprimir informacion relacionada con funciones especificas en perfil plano con `-pfuncname`

`gprof -pfucn1 test_gprof gmon.out > analysis.txt`

! snippet de ejecucion

#### _Generamos un grafico_

La herramienta `gprof2dot` nos permite generar una visualizacion de la salida de gprof.

! grafico generado

### Linux Perf

Es una pequeña herramienta que permite crear perfiles de programas. Esta utiliza perfiles estadisticos, donde sondea el programa y ve que funcion esta ejecutandose.

Es menos precisa pero tiene menos impacto en el rendimiento que otras opciones.

`sudo perf record ./examples/test_gprof`

`sudo perf report`

! snippet
