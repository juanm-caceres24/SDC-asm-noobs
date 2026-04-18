import requests
import ctypes

# Cargamos la libreria en C

libgini = ctypes.CDLL("./libgini.so")

# Declaramos la firma de la funcion en C
libgini.gini_convert.argtypes = [ctypes.c_float]
libgini.gini_convert.restype  = ctypes.c_int

# Recuperamos los datos
URL = (
    "https://api.worldbank.org/v2/country/arg/indicator/SI.POV.GINI"
    "?format=json&date=2011:2020"
)

response = requests.get(URL, timeout=10)
response.raise_for_status()
records = [ r for r in response.json()[1] if r.get('value') is not None]
records.sort(key=lambda r: r["date"])

# Llamamos la funcion en C

print(f"{'Año':<6} {'GINI (float)':<16} {'GINI (int) + 1'}")
print("-" * 36)

for record in records:
    year       = record["date"]
    gini_float = float(record["value"])
    gini_int1  = libgini.gini_convert(gini_float)

    print(f"{year:<6} {gini_float:<16.2f} {gini_int1}")