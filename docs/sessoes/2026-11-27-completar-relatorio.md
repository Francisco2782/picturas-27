# Completar o texto e o anexo do relatório da Fase 2

O utilizador autorizou as restantes correções de texto e pediu para adiar os
diagramas. O conteúdo relevante do rascunho de elasticidade em `stash@{0}` foi
integrado no texto corrente, preservando as revisões recentes do capítulo 10.
O relatório identifica `3cb1b74` como revisão das campanhas principais,
`c4ddc6c` como introdução da escala dinâmica e `c2f4a3f` como revisão de código
com a correção da lista de efeitos em projetos partilhados.

As alternativas rejeitadas de DA-2 receberam referências na tabela de táticas.
A matriz de efeitos distingue a redução da espera de B da operabilidade e
regista a preservação das permissões de cancelamento. O capítulo 2 separa o
progresso na baseline e após o refactoring na descrição da sequência. O anexo
explica o arranque da aplicação, a execução ao vivo e a verificação dos arquivos.
A recolha das assinaturas de revisão humana e a reprodução independente
continuam por registar.

Os dois arquivos passaram a verificação do SHA-256 exterior e dos manifestos
`SHA256SUMS` após extração em diretório vazio. `verify_final.py` confirmou
0,123429 s no QS-01 e 12/12 ações com 3/3 recuperações em cada percurso no QS-02.
`python3 instruments/summarize.py dynamic --runs 3` confirmou 7,902 s de espera
média no ensaio de elasticidade. Estas operações recontam medições existentes.

Os instrumentos extraídos de `afb84e5` e `3cb1b74` executaram `--help`. Só o
instrumento final aceita `--expected-workers`, pelo que o anexo dá comandos
separados. O PDF compilou com Tinymist em 43 páginas e as páginas da elasticidade
e do anexo foram conferidas após renderização. `git diff --check` passou e não
houve alterações no diretório `images/` do relatório.

## Continuação da revisão em 27/11/2026

A revisão da fonte confirmou que a evidência exploratória já aponta para
`comparison-baseline`, e não para `performance-retry`. A recontagem executada
com `PYTHONDONTWRITEBYTECODE=1 python3 evaluation/summarize.py
evaluation/evidence/phase2-final-2026-11-22/comparison-baseline --runs 3`
produziu três ensaios válidos e média de 82,242 s (intervalo
79,325–84,393 s). As correções textuais de referências, DA-2, segurança e Fase
3 já estavam presentes na fonte e foram preservadas.

Sem alterar os diagramas, a nota da vista posterior esclarece que
`processingRun` é um campo do documento do projeto e atribui ao worker a limpeza
dos seus ficheiros de staging após uma entrega interrompida. O anexo agora
identifica os checkouts e revisões, o número de workers, os comandos para obter
os dados de D-01 e a distinção entre recontagem de arquivos e repetição ao vivo.
O guia `evaluation/phase2-reproduction.md` aponta para os arquivos no caminho
local `evaluation/evidence/` e inicia cada procedimento a partir da raiz do
repositório.

O PDF foi recompilado para
`evaluation/evidence/output/pdf/picturas-fase2-main.pdf` com Tinymist 0.15.12.
`pdfinfo` e `pdftotext` leram o resultado de 43 páginas; a extração confirmou
que os títulos e o corpo não expõem qualificadores como «se existir»,
«pendente» ou «por confirmar». O comando de `pdfinfo` também emitiu o aviso
`Syntax Error: Suspects object is wrong type (boolean)`, igualmente observado
no PDF compilado antes desta revisão; a leitura de páginas e a extração de texto
continuaram a funcionar. `git diff --check` passou e o estado de Git confirma
que nenhum ficheiro em `images/` foi alterado.

A equipa confirmou que ainda não realizou revisão humana do relatório e do
registo de IA. Por isso, o capítulo 12 não afirma que tal revisão aconteceu;
esta verificação continua necessária para satisfazer integralmente o requisito
do enunciado. As correções dos diagramas também não foram feitas, conforme o
pedido de os deixar intactos; as respetivas observações da análise permanecem
fora das alterações desta ronda.

A última atualização explicitou uma réplica no ensaio de navegador da baseline
e duas na revisão final, de acordo com o protocolo arquivado. O PDF voltou a
ser compilado com 43 páginas; as páginas 40–42 foram renderizadas e conferidas
após esta alteração.

## Identificação do PDF antigo

Após indicação do utilizador de que ainda via «por confirmar», a extração de
texto foi repetida nos PDFs locais. O PDF atual
`evaluation/evidence/output/pdf/picturas-fase2-main.pdf` não contém marcadores
de pendência. O arquivo antigo `evaluation/evidence/picturas-phase2-relatorio-rascunho.pdf`
continua a conter os qualificadores do rascunho e não foi usado para a
compilação final nem incluído nas alterações a publicar.
