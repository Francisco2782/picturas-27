# Registo de implementação da Fase 2

Este documento regista cada incremento implementado, a respetiva validação e o
trabalho ainda pendente. As evidências oficiais da baseline permanecem na pasta
local `evaluation/evidence/`, ignorada pelo Git.

## Aprovação e ponto de partida

- A equipa aprovou a gate B-04 em 2026-11-17.
- Tag da baseline da aplicação: `phase2-base`, commit
  `052310226c51fa57a17101c7bd1ad795674aac95`.
- Branch de implementação: `main`, commit inicial
  `afb84e5c818820f807bb504a8ed9f0a3162cc9dd`.
- A implementação deve avançar por incrementos pequenos e cada incremento deve
  ficar documentado.

## Incremento U-01 — Estado persistente da execução

**Estado: concluído.**

### Alterações

- Acrescentado ao modelo Project o snapshot opcional `processingRun`. Guarda o
  token da execução atual, o estado e resultado, as datas de início/atualização/
  conclusão e o progresso mais recente de cada vídeo, incluindo a indicação de
  pré-visualização e a data da atualização.
- Criadas funções puras de transição para iniciar uma execução, aceitar progresso
  monotónico por vídeo e terminar com `completed`, `failed` ou `cancelled`.
  Guarda-se apenas a execução mais recente; uma execução nova substitui o
  snapshot terminal anterior.
- Os dois caminhos de início do processamento (com e sem ferramentas avançadas)
  guardam o estado `running` na mesma atualização que altera `activeToken`.
- Uma falha ao obter os ficheiros de origem, ao despachar o lote ou uma resposta
  de erro do worker marca como `failed` a execução ativa correspondente.
  O estado só passa a `completed` quando a execução ativa, com token igual,
  consegue fazer commit. O cancelamento guarda `cancelled` e mantém a invalidação
  existente através de `activeToken`.
- O commit verifica que a execução continua ativa e em estado `running`; uma
  resposta atrasada de outra tarefa do lote não transforma uma execução falhada
  ou terminal em sucesso. Projetos sem snapshot continuam a usar o caminho de
  commit anterior, para suportar trabalhos que já estivessem em curso durante a
  atualização.

### Validação

- `node --check routes/projects.js`
- `node --check controllers/project.js`
- `node --check models/project.js`
- `node --test tests/*.test.js`, executado em `projects/`: **14 aprovados, 0
  falhados**.
- Os testes cobrem criação da execução, IDs de media únicos, validação do
  schema, progresso monotónico, rejeição de tokens/datas antigos, precedência do
  estado terminal, cancelamento, commit condicionado ao token ativo e registo de
  falhas.

### Limites deste incremento e passo seguinte

Este incremento não altera filas nem comportamento do frontend. As transições de
progresso estão preparadas para U-02, que validará e guardará as mensagens do
worker. O snapshot autorizado e a interface recuperável pertencem a U-03 e U-04.

## Incremento P-01 — Escala limitada dos workers em Compose

**Estado: concluído.**

### Validação

- Iniciada a segunda réplica com
  `docker compose up -d --no-build --scale video_tool=2 video_tool`.
- Os dois containers usaram a imagem
  `sha256:5126bfec8ab05cd5dc981878aa9dabb4c4865a3c1475620ef8ec6b7a2961a975`
  e estavam em execução durante a observação.
- O RabbitMQ indicou dois consumidores ativos na `video_queue` existente; ambos
  exigem confirmação da mensagem (`ack`) e têm `prefetch_count=1`.
- Ambos os containers montam os mesmos volumes nomeados `image_data` e
  `whisper_models`.
- `docker-compose.yaml` não define substituição para o número de réplicas; o
  Compose local continua a iniciar uma réplica por omissão. Não foram alterados
  a fila nem o contrato de despacho.
- Evidência local do smoke test:
  `evaluation/evidence/phase2-p01-smoke-2026-11-17/`.

O ambiente fica com duas réplicas para os próximos testes de concorrência e
falhas. P-02 e P-03 continuam pendentes.

## Incrementos pendentes

- Ordem acordada em 2026-11-17: concluir Desempenho antes de retomar
  Usabilidade. P-01 e U-01 estão concluídas. Não iniciar U-02, U-03 ou U-04 antes
  de concluir P-02 e P-03.
- P-02 e P-03: segurança dos resultados em lotes concorrentes e comportamento
  perante recursos e falhas. P-01 passou o smoke test de escala limitada.
- Retomar Usabilidade em U-02, seguindo depois para U-03 e U-04.
- R-01 a R-04, M-01 a M-04 e D-01 a D-02: regressão, medições finais e relatório.
