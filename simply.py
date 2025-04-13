#!/usr/bin/env python3
# simplifies output from pathParser
# /se/sv/odd-molly/once-in-a-while-top_12876705/12876719/
# /se/sv/odd-molly/blabla/
# /se/sv/odd-molly/foofoo/
# /se/sv/odd-molly/barbar/
# returns /se/sv/odd-molly for lvl 3
# /se/sv/ for lvl 2
# /se/ for lvl 1 etc

import sys

if len(sys.argv) != 3:
    print("Usage: python3 simply.py <paths file> <lvl>")
    sys.exit(1)

archivo = sys.argv[1]
num_segmentos = int(sys.argv[2])

resultados = set()

with open(archivo, 'r') as f:
    for linea in f:
        linea = linea.strip().strip('/')
        if not linea:
            continue
        segmentos = linea.split('/')
        recorte = '/'.join(segmentos[:num_segmentos])
        resultados.add('/' + recorte + '/')

for ruta in sorted(resultados):
    print(ruta)
