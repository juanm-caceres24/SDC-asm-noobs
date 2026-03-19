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

<img width="2015" height="479" alt="image" src="https://github.com/user-attachments/assets/e2a8ede4-0d77-4121-b9e8-32bcf887dea9" />

#### _Ejecutamos el codigo_

Procedemos a ejecutar el archivo binario producido para generar la informacion de perfiles:

`./test_gprof`

Al ejecutar el binario vemos como se genera un nuevo archivo llamado `gmon.out` en el directorio de trabajo actual.

<img width="1615" height="200" alt="image" src="https://github.com/user-attachments/assets/d882daa5-db15-41d1-a68c-6a77ef4e9d58" />

#### _Ejecutamos gprof_

La herramienta se ejecuta con el nombre del ejecutable a analizar, y el archivo `gmon.out` producido anteriormente.

`gprof test_gprof gmon.out > analysis.txt`

Esto produce un archivo de analisis que contiene toda la informacion de perfil deseada `analysis.txt`.

<img width="1866" height="231" alt="image" src="https://github.com/user-attachments/assets/d48f110b-b5ac-42a3-a596-f3f327270238" />

#### _Interpretamos la informacion de perfil_

Analizamos el contenido del archivo generado:

```txt
Flat profile:

Each sample counts as 0.01 seconds.
  %   cumulative   self              self     total           
 time   seconds   seconds    calls   s/call   s/call  name    
 33.83      7.93     7.93        1     7.93    15.67  func1
 33.02     15.67     7.74        1     7.74     7.74  func2
 33.02     23.41     7.74        1     7.74     7.74  new_func1
  0.13     23.44     0.03                             main

granularity: each sample hit covers 4 byte(s) for 0.04% of 23.44 seconds

index % time    self  children    called     name
                                                 <spontaneous>
[1]    100.0    0.03   23.41                 main [1]
                7.93    7.74       1/1           func1 [2]
                7.74    0.00       1/1           func2 [3]
-----------------------------------------------
                7.93    7.74       1/1           main [1]
[2]     66.9    7.93    7.74       1         func1 [2]
                7.74    0.00       1/1           new_func1 [4]
-----------------------------------------------
                7.74    0.00       1/1           main [1]
[3]     33.0    7.74    0.00       1         func2 [3]
-----------------------------------------------
                7.74    0.00       1/1           func1 [2]
[4]     33.0    7.74    0.00       1         new_func1 [4]
-----------------------------------------------


Index by function name
   [2] func1                   [1] main
   [3] func2                   [4] new_func1
```

Podemos ver como el programa tardo un total de 23.44 segundos en ejecutarse, ey en la tabla podemos ver el tiempo que consumio cada funcion individualmente, incluyendo la ejecucion de su propio codigo, y el tiempo de las funciones que llama.

Interpretando el grafo vemos:
- main llama una vez a func1 y una vez a func2 --> su tiempo de ejecucion es casi todo de llamados
- func1 llama a new_func1 --> la mitad del tiempo es propio y la otra es de llamada
- func2 no llama a nadie --> todo su tiempo es propio
- new_func1 no llama a nadie --> todo su tiempo es propio

Podriamos decir que el punto de dolor mas grande aqui es func1 y su llamado a new_func1, ya que ocupan el 66% del tiempo de ejecucion.

#### _Customizando el output con flags_

Podemos suprimir la impresion de funciones declaradas estaticamente (privadas) con `-a`

`gprof -a test_gprof gmon.out > analysis.txt`

<img width="1901" height="210" alt="image" src="https://github.com/user-attachments/assets/1b8b2d0f-37cd-4080-82ed-daba0ab2f7d1" />

```txt
Flat profile:

Each sample counts as 0.01 seconds.
  %   cumulative   self              self     total           
 time   seconds   seconds    calls   s/call   s/call  name    
 time   seconds   seconds    calls   s/call   s/call  name    
 66.85     15.67    15.67        2     7.83    11.71  func1
 33.02     23.41     7.74        1     7.74     7.74  new_func1
  0.13     23.44     0.03                             main

granularity: each sample hit covers 4 byte(s) for 0.04% of 23.44 seconds

index % time    self  children    called     name
                                                 <spontaneous>
[1]    100.0    0.03   23.41                 main [1]
               15.67    7.74       2/2           func1 [2]
-----------------------------------------------
               15.67    7.74       2/2           main [1]
[2]     99.9   15.67    7.74       2         func1 [2]
                7.74    0.00       1/1           new_func1 [3]
-----------------------------------------------
                7.74    0.00       1/1           func1 [2]
[3]     33.0    7.74    0.00       1         new_func1 [3]
-----------------------------------------------
```

Podemos eliminar los textos detallados usando `-b`

`gprof -b test_gprof gmon.out > analysis.txt`

<img width="1897" height="754" alt="image" src="https://github.com/user-attachments/assets/e3ee623f-660a-425b-9735-8f9bf94e7fa9" />

Podemos imprimir solo el perfil plano usando `-p`

`gprof -p test_gprof gmon.out > analysis.txt`

<img width="1897" height="862" alt="image" src="https://github.com/user-attachments/assets/d7536bfb-b920-4c23-bd4d-e8f0d5b69d1b" />

Podemos imprimir informacion relacionada con funciones especificas en perfil plano con `-pfuncname`

`gprof -pfucn1 test_gprof gmon.out > analysis.txt`

<img width="1941" height="803" alt="image" src="https://github.com/user-attachments/assets/08b29648-f6f4-4c89-bf3e-4865a165c16a" />

#### _Generamos un grafico_

La herramienta `gprof2dot` nos permite generar una visualizacion de la salida de gprof.

<img width="2120" height="1184" alt="image" src="https://github.com/user-attachments/assets/658ffc45-e45e-4703-8470-fd63faf2284e" />

### Linux Perf

Es una pequeña herramienta que permite crear perfiles de programas. Esta utiliza perfiles estadisticos, donde sondea el programa y ve que funcion esta ejecutandose.

Es menos precisa pero tiene menos impacto en el rendimiento que otras opciones.

`sudo perf record ./examples/test_gprof`

`sudo perf report`

<img width="769" height="1386" alt="image" src="https://github.com/user-attachments/assets/b6d7ec88-183b-45bc-b997-f5ddc50f1453" />
