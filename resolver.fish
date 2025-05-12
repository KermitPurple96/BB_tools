#!/usr/bin/env fish

function resolver
    if test (count $argv) -ne 2
        echo "Uso: ./resolver.fish <dominio> <archivo_subdominios>"
        return 1
    end

    set dominio $argv[1]
    set subdoms $argv[2]
    set outdir "./resolver"
    set outfile (realpath "$outdir/resolver-$dominio.txt")

    # Asegura que ./resolver exista en el directorio actual
    if not test -d $outdir
        echo "[*] Creando directorio de salida $outdir..."
        mkdir -p $outdir
    end

    # Verifica el archivo de subdominios antes de seguir
    if not test -f "$subdoms"
        echo "❌ No se encontró el archivo de subdominios: $subdoms"
        return 1
    end

    echo "[*] Ejecutando BASS..."
    python3 /home/kermit/bass/bass.py -d $dominio -o $outfile

    echo "[*] Ejecutando dnsgen + massdns..."
    cat "$subdoms" | dnsgen - | /home/kermit/massdns/bin/massdns \
        -r $outfile \
        -t A -o S -w $outdir/dnsgen-$dominio.txt

    echo "[*] Filtrando resultados válidos..."
    cat $outdir/dnsgen-$dominio.txt | awk -F"'" '{print $1}' | rev | cut -c 2- | rev | sort -u | tee $outdir/filt-dnsgen-$dominio.txt

    echo "[✓] Finalizado. Resultados en: $outdir/"
end

resolver $argv
