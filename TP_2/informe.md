# Trabajo Practico N°2

## Calculadora de Indices

**Materia:** Sistemas de Computación  
**Grupo:** asm_noobs  
**Integrantes:** [Fabian Nicolas Hidalgo] · [Juan Manuel Caceres] · [Agustin Alvarez]

---

### Introducción

El presente trabajo práctico consiste en el diseño e implementación de un sistema multicapa para consultar y procesar el índice GINI desde la API del Banco Mundial. El sistema se estructura en tres capas:

- **Capa superior (Python):** consume la API REST y pasa los datos a la capa intermedia.
- **Capa intermedia (C):** recibe los datos flotantes y llama a rutinas en assembler.
- **Capa inferior (Assembler x86-64):** realiza la conversión de float a entero y le suma uno, devolviendo el resultado mediante el stack.

#### El índice GINI

Es una medida estadística que cuantifica la desigualdad en la distribución del ingreso dentro de una población. Su valor oscila entre 0 y 100, donde 0 representa una igualdad perfecta (todos los individuos tienen el mismo ingreso) y 100 representa una desigualdad máxima (una sola persona concentra todo el ingreso).

Los datos se obtienen de la API REST pública del Banco Mundial, que devuelve registros en formato JSON con el valor del índice GINI por país y por año. 

```
https://api.worldbank.org/v2/en/country/all/indicator/SI.POV.GINI?format=json&date=2011:2020&per_page=32500&page=1&country="Argentina"
```

#### Iteraciones

**Iteración 1 — Python + C sin Assembler:** se construye la arquitectura completa del sistema (consulta a la API, paso de datos a C, cálculo y muestra de resultados) usando solo Python y C. El objetivo es validar el flujo de datos y la integración entre capas antes de introducir assembler, de modo que los errores de lógica puedan aislarse de los errores de bajo nivel.

**Iteración 2 — Integración con Assembler:** se reemplaza la lógica de conversión `float → entero` y la operación de suma `+1` por una rutina escrita en NASM. C actúa como puente, invocando la función de Assembler y pasándole los parámetros conforme a la ABI. Se utiliza GDB para mostrar el estado del stack en los tres momentos clave de la llamada: antes, durante y después.

---

### Arquitectura

...

---

### Iteracion #1

...

#### Python

...

#### C

...

---

### Iteracion #2

...

#### Assembler

...

#### C

...

---

### Call Conventions

...

#### Registros

...

#### Stack Frame

...

---

### GDB Analisis

...

#### Configuracion

...

#### Stack antes de `call`

...

#### Stack durante `call`

...

#### Stack despues de `call`

...

---

### Resultados

...

---

### Dificultades

...

---

### Conclusiones

...

---

### Referencias

[] - ref_one_ex

[] - ref_two_ex