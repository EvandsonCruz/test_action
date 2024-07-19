name: checks-deploy

on:
  pull_request:
    types:
      - opened
      - synchronize
      - reopened
      - edited
    paths-ignore:
      - '.github/workflows/**'

jobs:
  validar-identificador:
    runs-on: deploy

    steps:
      - name: Checkout do repositório
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Configurar variável de ambiente GH_TOKEN
        run: echo "GH_TOKEN=${{ secrets.DEVOPS_TOKEN }}" >> $GITHUB_ENV 

      - name: Obter conteúdo do pull request
        run: |
          # Obtém a lista de arquivos adicionados no pull request
          arquivos_adicionados=($(git diff --name-only HEAD^1))

          encontrada=false  # Inicializa encontrada como falso fora do loop
          saida=""  # Inicializa a variável de saída

          for arquivo in "${arquivos_adicionados[@]}"; do
            echo "Validando arquivo adicionado: $arquivo"
            identificador=$(grep -Eo '\.[[:alnum:]_]{31,}' "$arquivo" | head -n 1 | sed 's/\.//')  # Pega apenas a primeira ocorrência

            if [ -n "$identificador" ]; then
              echo "Identificador de objeto ${identificador} com mais de 30 caracteres no arquivo: $arquivo"
              encontrada=true
              saida+="Identificador de objeto ${identificador} com mais de 30 caracteres no arquivo $arquivo"$'\n'
            fi
          done

          if [ "$encontrada" == true ]; then
            echo "::error::Encontrado identificador de objeto com mais de 30 caracteres"
            SLACK_MESSAGE="Identifier too long PR ${{ github.event.number }} - github.com/${GITHUB_REPOSITORY}/pull/${{ github.event.number }}/files (${{ github.base_ref }})\n$saida"
            curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
            PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
            REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
            REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
            AUTHOR_NAME=${{ github.event.pull_request.user.login }}
            gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
            ${saida}Por favor revisar."
            exit 1
          else
            echo "Não encontrado identificador de objeto com mais de 30 caracteres"
          fi

  validar-extensao:
    runs-on: deploy

    steps:
      - name: Checkout do repositório
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Configurar variável de ambiente GH_TOKEN
        run: echo "GH_TOKEN=${{ secrets.DEVOPS_TOKEN }}" >> $GITHUB_ENV

      - name: Listar arquivos do pull request
        id: listar-arquivos
        run: |
          git diff --name-only HEAD^1 > files.txt
          cat files.txt

      - name: Verificar extensão de arquivos
        run: |
          tem_erro=false
          saida=""
          for arquivo in $(cat files.txt); do
            if [[ "$arquivo" != *.* ]]; then
              echo "############arquivo###########  $arquivo"
              echo "::warning::ERRO: O arquivo $arquivo não tem uma extensão. Todos os arquivos devem ter extensão."
              tem_erro=true
              saida="$saida$arquivo"$'\n'
              echo "##########saida########### $saida"
            fi
          done

          if [ "$tem_erro" = true ]; then
            echo "Enviando notificação para o Slack..."
            SLACK_MESSAGE="ERRO: Todos os arquivos devem ter extensão. PR: ${{ github.event.number }} - github.com/${GITHUB_REPOSITORY}/pull/${{ github.event.number }}/files (${{ github.base_ref }})\nUm ou mais arquivos no pull request não tem extensão:\n$saida"
            curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
            PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
            REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
            REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
            AUTHOR_NAME=${{ github.event.pull_request.user.login }}
            gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
            Um ou mais arquivos não tem extensão:
            ${saida}Por favor revisar."
            exit 1
          else
            echo "Todos os arquivos tem extensão."
          fi

  validar-quantidade:
    runs-on: deploy

    steps:
      - name: Checkout do repositório
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Configurar variável de ambiente GH_TOKEN
        run: echo "GH_TOKEN=${{ secrets.DEVOPS_TOKEN }}" >> $GITHUB_ENV 

      - name: Obter conteúdo do pull request
        id: obter-conteudo
        run: |
          # Obtém a lista de arquivos adicionados no pull request
          arquivos_adicionados=($(git diff --name-only HEAD^1))
          quantidade_arquivos=${#arquivos_adicionados[@]}
          if [ "$quantidade_arquivos" -gt 70 ]; then
            echo "::warning::Grande quantidade de arquivos sendo alterados ($quantidade_arquivos)"
            SLACK_MESSAGE="Grande quantidade de arquivos sendo alterados ($quantidade_arquivos) no PR ${{ github.event.number }} - github.com/${GITHUB_REPOSITORY}/pull/${{ github.event.number }}/files (${{ github.base_ref }})"
            curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
            PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
            REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
            REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
            AUTHOR_NAME=${{ github.event.pull_request.user.login }}
            gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
            Grande quantidade de arquivos sendo alterados ($quantidade_arquivos)
            Por favor revisar a branch comparada"
            exit 1
          else
            echo "Quantidade de arquivos alterados dentro do esperado"
          fi

  validar-barra:
    runs-on: deploy

    steps:
      - name: Checkout do repositório
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Configurar variável de ambiente GH_TOKEN
        run: echo "GH_TOKEN=${{ secrets.DEVOPS_TOKEN }}" >> $GITHUB_ENV 

      - name: Obter conteúdo do pull request
        id: obter-conteudo
        run: |
          # Obtém a lista de arquivos adicionados no pull request
          arquivos_adicionados=($(git diff --name-only HEAD^1))
          encontrada=false  # Inicializa encontrada como falso fora do loop
          check=""  # Inicializa a variável de saída
          for arquivo in "${arquivos_adicionados[@]}"; do
            if grep -Ei -q '(create|alter) (table|index|sequence)' "$arquivo"; then
              echo "Validando arquivo adicionado: $arquivo"
              check=$(awk '/;.*$/{flag=1; next} /\/$/{if(flag){print "Encontrado ;/ no arquivo"}} {flag=0}' "$arquivo")
              if [[ -n "$check" ]]; then
                echo "O arquivo $arquivo tem ; e /. Isso pode causar erro por tentativa de execução duplicada"
                encontrada=true
                saida+="$saida$arquivo"$'\n'
              fi
            fi
          done
          if [ "$encontrada" == true ]; then
            echo "::error::Existe arquivo no PR que tem ; e /. Isso pode causar erro por tentativa de execução duplicada"
            SLACK_MESSAGE="Existe arquivo no PR que tem ; e /.  PR - ${{ github.event.number }} - github.com/${GITHUB_REPOSITORY}/pull/${{ github.event.number }}/files (${{ github.base_ref }})\n$saida"
            curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
            PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
            REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
            REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
            AUTHOR_NAME=${{ github.event.pull_request.user.login }}
            gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
            ${saida}Por favor revisar."
            exit 1
          else
            echo "Não encontrado arquivo com ; e /"
          fi
