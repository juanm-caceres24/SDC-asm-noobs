#include <stdio.h>

int gini_convert(float gini_value) {
    // truncamos los decimales
    int as_int = (int) gini_value;
    return as_int + 1;
}