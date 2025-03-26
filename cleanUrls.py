import sys
import re
from urllib.parse import urlparse, urlunparse
from pathlib import Path

# python parseUrls.py results4.txt filtered_results4.txt inlanefreight.local -all
# python parseUrls.py results4.txt filtered_results4.txt inlanefreight.local .html .php -dir
# generates all possible real URLS from url file
# http://app.inlanefreight.local/administrator/
# http://app.inlanefreight.local/administrator/index.php
# http://app.inlanefreight.local/administrator/templates/
# http://app.inlanefreight.local/administrator/templates/images/

def limpiar_url(url):
    return re.split(r"[#?,;]", url.strip())[0]

def es_archivo(path):
    return '.' in Path(path).name  # si contiene extensión

def normalizar_url(url):
    parsed = urlparse(url)
    path = parsed.path

    if es_archivo(path):
        path = path.rstrip('/')  # sin slash final
    else:
        path = path.rstrip('/') + '/'  # con slash final

    return urlunparse((parsed.scheme, parsed.netloc, path, '', '', ''))

def extraer_paths_completos(url):
    parsed = urlparse(url)
    if not parsed.scheme or not parsed.netloc:
        return []

    partes = parsed.path.strip('/').split('/')
    rutas = []

    for i in range(1, len(partes) + 1):
        subpath = '/' + '/'.join(partes[:i])
        if not es_archivo(subpath):
            subpath += '/'
        nueva_url = urlunparse((parsed.scheme, parsed.netloc, subpath, '', '', ''))
        rutas.append(nueva_url)

    return rutas

def parse_urls(input_file, output_file, domain_filter, include_originals=False):
    rutas_resultantes = set()

    with open(input_file, 'r') as f:
        urls = [limpiar_url(line) for line in f if line.strip()]

    for url in urls:
        url = normalizar_url(url)
        parsed = urlparse(url)
        if domain_filter not in parsed.netloc:
            continue

        rutas_resultantes.update(map(normalizar_url, extraer_paths_completos(url)))

        if include_originals:
            rutas_resultantes.add(url)

    with open(output_file, 'w') as f:
        for ruta in sorted(rutas_resultantes):
            f.write(ruta + '\n')

    print(f"[+] Rutas procesadas y guardadas en '{output_file}'")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python script.py <archivo_entrada> <archivo_salida> <dominio> [-all]")
        sys.exit(1)

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2])
    domain_filter = sys.argv[3]
    include_originals = '-all' in sys.argv

    if not input_file.is_file():
        print(f"Error: El archivo de entrada '{input_file}' no existe.")
        sys.exit(1)

    parse_urls(input_file, output_file, domain_filter, include_originals)
