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
             #echo "##########################arquivos_adicionados###################################  $arquivos_adicionados"

             encontrada=false  # Inicializa encontrada como falso fora do loop
             saida=""  # Inicializa a variável de saída

             for arquivo in "${arquivos_adicionados[@]}"; do
             echo "Validando arquivo adicionado: $arquivo"
             identificador=$(grep -Eo '\.[[:alnum:]_]{31,}' "$arquivo" | head -n 1 | sed 's/\.//')  # Pega apenas a primeira ocorrência

             if [ -n "$identificador" ]; then
               echo "Identificador de objeto ${identificador} com mais de 30 caracteres no arquivo: $arquivo"
               encontrada=true
               saida+="Identificador de objeto ${identificador} com mais de 30 caracteres no arquivo $arquivo"$'\n'
               #echo "identificador >>>>>>>>>>>>>>>>>>>>>> $identificador"
             fi

             #echo "##########################contagem depois do if###################################  $contagem"
             done
             #echo ">>>>>>>depois do for>>>>>>>>>>>>> $encontrada"

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
