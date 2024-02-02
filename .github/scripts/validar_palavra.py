# Arquivo: .github/scripts/validar_palavra.py
import os
import sys

def validar_palavra(palavra_chave, arquivos):
    encontradas = []

    for arquivo in arquivos:
        with open(arquivo, 'r', encoding='utf-8') as f:
            for numero_linha, linha in enumerate(f.readlines(), start=1):
                if palavra_chave in linha:
                    encontradas.append(f"'{palavra_chave}' encontrada no arquivo '{arquivo}' na linha {numero_linha}: {linha.strip()}")

    return encontradas

if __name__ == "__main__":
    palavra_chave = sys.argv[1]
    arquivos_modificados = sys.argv[2:]

    resultados = validar_palavra(palavra_chave, arquivos_modificados)

    if resultados:
        print("Palavra '{0}' encontrada no meio da linha nos seguintes lugares:".format(palavra_chave))
        for encontrada in resultados:
            print("- {0}".format(encontrada))
        sys.exit(1)
    else:
        print("Nenhuma ocorrência da palavra '{0}' no meio da linha nos arquivos do PR.".format(palavra_chave))
