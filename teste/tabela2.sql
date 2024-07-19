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
          Existe arquivo no PR que tem ; e /
          ${saida}Isso pode causar erro por tentativa de execução duplicada
          Por favor revisar, manter somente a /"
          exit 1
        else
          echo "PR OK"
        fi

validar-tablespace:
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
        encontrada=false
        saida=""
        echo "Pull request acabou de ser aberto. Verificando novos arquivos adicionados."
        # Obtém a lista de arquivos adicionados no pull request
        arquivos_adicionados=($(git diff --name-only HEAD^1))
        echo "Arquivos adicionados: ${arquivos_adicionados[@]}"
        for arquivo in "${arquivos_adicionados[@]}"; do
          echo "Verificando o arquivo: $arquivo"
          if awk '/create index/ && !/tablespace/' "$arquivo" | grep -q "."; then
            encontrada=true
            saida="$saida$arquivo"$'\n'
          else
            echo "index OK"
          fi
        done
        if [ "$encontrada" == true ]; then
          echo "::error::Criação de índice sem tablespace"
          SLACK_MESSAGE="Criação de índice sem tablespace no PR - ${{ github.event.number }} - github.com/${GITHUB_REPOSITORY}/pull/${{ github.event.number }}/files (${{ github.base_ref }})\n$saida"
          curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
          PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
          REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
          REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
          AUTHOR_NAME=${{ github.event.pull_request.user.login }}
          gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
          Criação de índice sem tablespace
          ${saida}Por favor revisar."
          exit 1
        else
          echo "PR OK"
        fi

validar-colunas:
  runs-on: deploy
  steps:
    - name: Checkout do repositório
      uses: actions/checkout@v2
      with:
        fetch-depth: 0
    - name: Configurar variável de ambiente GH_TOKEN
      run: echo "GH_TOKEN=${{ secrets.DEVOPS_TOKEN }}" >> $GITHUB_ENV 
    - name: Obter lista de arquivos alterados
      run: |
        problemas=false
        mensagem_erro=""
        colunas=("ID_USR_ATLZ" "ID_USR_INCL" "DT_ATLZ" "DT_INCL")
        arquivos_alterados=$(git diff --name-only HEAD^1)
        for arquivo in $arquivos_alterados; do
          if grep -qiE 'CREATE TABLE' "$arquivo"; then
            colunas_faltando=()
            for coluna in "${colunas[@]}"; do
              if ! grep -qiE "$coluna" "$arquivo"; then
                problemas=true
                colunas_faltando+=("$coluna")
              fi
            done
            if [ ${#colunas_faltando[@]} -ne 0 ]; então
              colunas_faltando_str=""
              for coluna in "${colunas_faltando[@]}"; do
                colunas_faltando_str+="$coluna, "
              done
              colunas_faltando_str=${colunas_faltando_str%, } # Remove a última vírgula e espaço
              mensagem_erro+="Arquivo: $arquivo, Colunas faltando: $colunas_faltando_str\n"
            fi
          fi
        done
        if [ "$problemas" = true ]; então
          mensagem_erro=$(echo -e "$mensagem_erro" | sed 's/\n$//')
          echo "::error::A criação de tabela não tem todos os campos de auditoria necessários: $mensagem_erro"
          SLACK_MESSAGE="PR ${{ github.event.number }} - github.com/${{ github.repository }}/pull/${{ github.event.number }}/files (${{ github.base_ref }})\n\nA criação da tabela nos seguintes arquivos não tem todos os campos de auditoria necessários:\n$mensagem_erro"
          curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
          
          PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
          REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
          REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
          AUTHOR_NAME=${{ github.event.pull_request.user.login }}
          gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
          A criação da tabela nos seguintes arquivos não tem todos os campos de auditoria necessários:
          ${mensagem_erro}"
          exit 1
        else
          echo "Todas as tabelas têm os campos de auditoria necessários."
        fi
