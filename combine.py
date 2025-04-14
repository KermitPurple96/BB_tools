import sys
import os

def normalizar_dominio(dominio: str) -> str:
    dominio = dominio.strip()
    if not dominio.startswith("http://") and not dominio.startswith("https://"):
        dominio = "https://" + dominio
    return dominio.rstrip("/")

def normalizar_path(path: str) -> str:
    path = path.strip()
    return path if path.startswith("/") else "/" + path

def cargar_lineas_archivo(nombre_archivo: str) -> list:
    if not os.path.isfile(nombre_archivo):
        print(f"Archivo no encontrado: {nombre_archivo}")
        sys.exit(1)
    with open(nombre_archivo, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]

def generar_urls(dominios: list, paths: list) -> list:
    urls = []
    for dominio in dominios:
        d = normalizar_dominio(dominio)
        for path in paths:
            p = normalizar_path(path)
            urls.append(f"{d}{p}")
    return urls

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python combinar_urls.py <archivo_dominios> <archivo_paths>")
        sys.exit(1)

    archivo_dominios = sys.argv[1]
    archivo_paths = sys.argv[2]

    dominios = cargar_lineas_archivo(archivo_dominios)
    paths = cargar_lineas_archivo(archivo_paths)

    urls = generar_urls(dominios, paths)

    for url in urls:
        print(url)

    with open("urls_generadas.txt", "w", encoding="utf-8") as f:
        for url in urls:
            f.write(url + "\n")
