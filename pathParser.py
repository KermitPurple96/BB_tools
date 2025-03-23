#!/usr/bin/python3
# extracts all paths from urls file made with something like https://github.com/hakluke/hakrawler 
# give urls file as 1st arg and paths file to save the output as 2nd
# ./pathParser.py urls paths
# example output:
# /wp-admin/
# /wp-admin/admin-ajax.php/
# /wp-admin/js/
# /wp-admin/js/password-strength-meter.min.js/

import sys
from pathlib import Path
from urllib.parse import urlparse

def extraer_rutas(url):
    parsed = urlparse(url)
    if not parsed.path:
        return []
    
    partes = parsed.path.strip('/').split('/')
    rutas = []
    for i in range(len(partes), 0, -1):
        rutas.append('/' + '/'.join(partes[:i]) + '/')
    return rutas

def procesar_archivo(input_file, output_file):
    rutas_extraidas = set()

    with open(input_file, 'r') as f:
        urls = [line.strip() for line in f if line.strip()]

    for url in urls:
        rutas_extraidas.update(extraer_rutas(url))

    with open(output_file, 'w') as f:
        for ruta in sorted(rutas_extraidas):
            f.write(ruta + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python script.py <archivo_entrada> <archivo_salida>")
        sys.exit(1)

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2])

    if not input_file.is_file():
        print(f"Error: El archivo de entrada '{input_file}' no existe.")
        sys.exit(1)

    procesar_archivo(input_file, output_file)
    print(f"Rutas extraídas y guardadas en '{output_file}'.")
