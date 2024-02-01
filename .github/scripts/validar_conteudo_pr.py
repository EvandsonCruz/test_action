import os
import sys

def validar_conteudo_pr():
    palavra_chave = "alter"  # Substitua com a palavra-chave desejada
    encontrada = False

    # Listar arquivos modificados no PR
    arquivos_modificados = os.popen("git diff --name-only ${{ github.event.before }} ${{ github.sha }}").read().splitlines()

    for arquivo in arquivos_modificados:
        with open(arquivo, 'r', encoding='utf-8') as f:
            conteudo = f.read()
            if palavra_chave in conteudo:
                encontrada = True
                print(f"A palavra-chave '{palavra_chave}' foi encontrada no arquivo: {arquivo}")

    if encontrada:
        print(f"A palavra-chave '{palavra_chave}' FOI encontrada em nenhum arquivo do PR.")
    else:
        print(f"A palavra-chave '{palavra_chave}' NÃO foi encontrada em nenhum arquivo do PR.")

if __name__ == "__main__":
    validar_conteudo_pr()
