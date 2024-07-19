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
            if [ ${#colunas_faltando[@]} -ne 0 ]; then
              colunas_faltando_str=""
              for coluna in "${colunas_faltando[@]}"; do
                colunas_faltando_str+="$coluna, "
              done
              colunas_faltando_str=${colunas_faltando_str%, } # Remove a última vírgula e espaço
              mensagem_erro+="Arquivo: $arquivo, Colunas faltando: $colunas_faltando_str\n"
            fi
          fi
        done
        if [ "$problemas" = true ]; then
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
        $mensagem_erro"
        exit 1
        else
          echo "PR OK"
        fi
		
  validar-encoding:
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
        arquivos_alterados=($(git diff --name-only HEAD^1))
        for arquivo in "${arquivos_alterados[@]}"; do
          encoding_info=$(file -i "$arquivo" | awk -F "=" '{print $2}' | tr -d ' ')
          if [ "$encoding_info" != "us-ascii" ] && [ "$encoding_info" != "utf-8" ] && [ "$encoding_info" != "iso-8859-1" ]; then
            echo ">>>>>>>>>>>>>>>> $encoding_info"
            echo "::error::O arquivo $arquivo não está codificado como UTF-8."
            saida+="$arquivo"$'\n'
            encontrado=true
          fi
        done
        
        if [ "$encontrado" == true ]; then
          SLACK_MESSAGE="UTF-8 Encoding Error PR ${{ github.event.number }} - github.com/${GITHUB_REPOSITORY}/pull/${{ github.event.number }}/files (${{ github.base_ref }})
          Existe arquivo que não está codificado como UTF-8.\n$saida"
          curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
          PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
          REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
          REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
          AUTHOR_NAME=${{ github.event.pull_request.user.login }}
          gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
         Existe arquivo que não está codificado como UTF-8.
          $saida Por favor, corrija o encoding e faça um novo commit."
          exit 1
        fi
		
  validar-grant:
    runs-on: deploy

    steps:
      - name: Checkout do código
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Configurar variável de ambiente GH_TOKEN
        run: echo "GH_TOKEN=${{ secrets.GH_TOKEN }}" >> $GITHUB_ENV 

      - name: Imprimir alterações
        run: |
          echo "Referência antes do evento: ${{ github.event.before }}"
          echo "SHA do commit atual: ${{ github.sha }}"
          git diff --name-only ${{ github.event.before }} ${{ github.sha }}  

      - name: Verificar Conteúdo do PR
        run: |
          palavras_chave=("grant")  # Substitua pela lista de palavras-chave desejada
          outras_palavras=("to public")  # Substitua pela segunda lista de palavras 

          encontrada=false 
          saida=""

          echo ">>>>>>>>>antes do for>>>>>>>>>>> $encontrada"
          echo "#############################################################  ${{ github.event_name }}"
          echo "##########################opened###################################  ${{ github.event.action }}"
          
           if [[ "${{ github.event.action }}" == "opened" || "${{ github.event.action }}" == "reopened"  ]]; then
            echo "Pull request acabou de ser aberto. Verificando novos arquivos adicionados."

            # Obtém a lista de arquivos adicionados no pull request
            arquivos_adicionados=($(git diff --name-only HEAD^1))
            echo "##########################arquivos_adicionados###################################  $arquivos_adicionados"

            for arquivo in "${arquivos_adicionados[@]}"; do
              echo "Novo arquivo adicionado: $arquivo"

              # Restante do seu código para verificar palavras-chave e outras_palavras
              for palavra_chave in "${palavras_chave[@]}"; do
                if grep -q -i "$palavra_chave" "$arquivo"; then
                  echo "Encontrada a palavra '$palavra_chave' no novo arquivo: $arquivo"
                  for outra_palavra in "${outras_palavras[@]}"; do
                    if grep -q -i "$outra_palavra" "$arquivo"; then
                      echo "Encontrada a palavra '$outra_palavra' no mesmo arquivo: $arquivo"
                      encontrada=true
                      saida="$saida$palavra_chave $outra_palavra no arquivo $arquivo\n"
                    fi
                  done
                fi
              done
            done
          else 
            for arquivo in $(git diff --name-only ${{ github.event.before }} ${{ github.sha }}); do
              for palavra_chave in "${palavras_chave[@]}"; do
                if grep -q -i "$palavra_chave" "$arquivo"; then
                  echo "Encontrada a palavra '$palavra_chave' no arquivo: $arquivo"
                  for outra_palavra in "${outras_palavras[@]}"; do
                    if grep -q -i "$outra_palavra" "$arquivo"; then
                      echo "Encontrada a palavra '$outra_palavra' no mesmo arquivo: $arquivo"
                      encontrada=true
                      saida="$saida$palavra_chave $outra_palavra no arquivo $arquivo\n"
                    fi
                  done
                fi
              done
            done
          fi
          
          echo ">>>>>>>depois do for>>>>>>>>>>>>> $encontrada"

          if [ "$encontrada" == true ]; then
            echo "::error::Encontrado grant to public"
            SLACK_MESSAGE="Grant to public no PR: ${{ github.event.number }} - github.com/${GITHUB_REPOSITORY}/pull/${{ github.event.number }}/files (${{ github.base_ref }})\n$saida"
            curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$SLACK_MESSAGE"'"}' ${{ secrets.SLACK_WEBHOOK_HML_DATABASE }}
            PR_NUMBER=$(echo "${{ github.event.pull_request.html_url }}" | awk -F'/' '{print $NF}')
            REPO_OWNER=$(echo "${{ github.repository }}" | cut -d '/' -f 1)
            REPO_NAME=$(echo "${{ github.repository }}" | cut -d '/' -f 2)
            AUTHOR_NAME=${{ github.event.pull_request.user.login }}
            gh pr comment $PR_NUMBER -R $REPO_OWNER/$REPO_NAME --body "@$AUTHOR_NAME
            ${saida}
            Por favor revisar."
            exit 1
          else
            echo "PR OK"
          fi
