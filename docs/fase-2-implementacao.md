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

## Incremento P-02 — Segurança de resultados em lotes concorrentes

**Estado: concluído.**

### Alterações

- O orquestrador regista todos os trabalhos do lote antes de os enviar à fila.
  Se o registo ou o envio falhar, remove apenas os trabalhos criados para esse
  lote e marca a execução ativa como falhada.
- Um trabalho mantém o seu registo `Process` até guardar o resultado. Assim,
  uma resposta rápida não faz o projeto parecer concluído enquanto ainda há
  vídeos do mesmo lote em processamento.
- O último resultado a terminar tenta concluir a execução. A atualização só é
  aceite se o token e o estado ainda forem os da execução ativa. Respostas
  atrasadas depois de cancelamento/falha são removidas e não podem concluir a
  execução.
- O envio para ferramentas aguarda confirmação do RabbitMQ. Falhas tardias de
  publicação passam a ser detetadas pelo orquestrador.
- O cancelamento por falha invalida o token ativo, remove os trabalhos dessa
  execução e elimina os seus resultados temporários.
- Corrigida a transição terminal para converter o subdocumento do Mongoose num
  objeto simples. Sem isso, os resultados eram guardados e o token era marcado
  como concluído, mas `processingRun` ficava em `running`.

### Validação

- `node --check` nos ficheiros JavaScript alterados.
- `node --test tests/*.test.js`, executado em `projects/`: **18 aprovados, 0
  falhados**. Inclui falha durante publicação, rollback limitado ao lote,
  resultados fora de ordem, resultado atrasado após cancelamento e transição a
  partir de um subdocumento Mongoose.
- Smoke test integrado num projeto temporário, com duas réplicas: um vídeo de
  60 segundos e outro de 6 segundos. O curto terminou primeiro. Nesse momento,
  o lote continuou `running`, havia um resultado guardado e um `Process` pendente;
  o token anterior continuou como último commit. Depois do vídeo longo terminar,
  o lote passou uma única vez para `completed`, com dois resultados no mesmo
  token e nenhum `Process` pendente.
- O teste encontrou a transição Mongoose descrita acima. Após a correção, a
  execução integrada terminou com progresso `100` nos dois vídeos. O projeto e
  os ficheiros temporários usados no teste foram removidos.

## Incremento P-03 — Recursos e falhas do worker de vídeo

**Estado: concluído.**

### O que foi verificado

- As saídas intermediárias usam ficheiros temporários no diretório do resultado;
  a saída final só substitui o destino depois de o processamento terminar.
- Em erro, o worker remove o ficheiro parcial. Subtítulos e extração de frames
  usam diretórios temporários que são limpos ao sair do processamento.
- Cada réplica mantém no máximo um trabalho ativo (`prefetch_count=1`). A cache
  do modelo Whisper usa o volume partilhado `whisper_models`; os caminhos de
  entrada e saída ficam no volume partilhado `image_data`.
- O worker confirma a mensagem apenas depois de enviar a resposta de sucesso ou
  erro. O serviço usa `restart: on-failure`; uma perda de ligação encerra o
  processo e permite ao Compose reiniciá-lo.
- Smoke test através de RabbitMQ: um vídeo com efeito comum e um vídeo com
  legendas foram processados por réplicas diferentes. Ambos produziram MP4s
  válidos; as legendas foram testadas numa amostra de 8 segundos.
- Após reiniciar RabbitMQ, os dois workers voltaram a ficar ativos e a consumir
  `video_queue`, cada um com `prefetch_count=1`. O contador de reinícios passou
  de 277 para 279 e nenhum worker foi marcado como terminado por OOM.
- Durante um vídeo de 60 segundos, uma amostragem de 1 segundo observou no worker
  ativo um pico de **271,6% de CPU** e **1,85 GiB de memória**. O worker que
  recebeu o vídeo curto ficou praticamente inativo. Não há limite artificial de
  CPU ou memória definido no serviço.
- Depois dos testes, não ficaram ficheiros `.part` nem diretórios temporários
  no projeto descartável. O cache Whisper continuou no volume partilhado.
- `.venv/bin/python -m pytest -q tests`, em `Tools/video/`: **74 aprovados**.
  Há um aviso de depreciação do Pillow num teste; não afeta o resultado.

### Observação

Ao reiniciar RabbitMQ, os workers recuperaram pela política do Compose. O serviço
`projects` saiu e precisou de ser iniciado novamente; a recuperação automática
desse consumidor não faz parte desta tarefa e fica registada para acompanhamento.

## Incrementos pendentes

- Ordem acordada em 2026-11-17: concluir Desempenho antes de retomar
  Usabilidade. P-01, P-02 e P-03 estão concluídas; U-01 também está concluída.
- U-02 também está concluída; o próximo incremento acordado é U-03, seguindo
  depois para U-04.
- R-01 a R-04, M-01 a M-04 e D-01 a D-02: regressão, medições finais e relatório.

## Incremento U-02 — Persistir o progresso enviado pelo worker

**Estado: concluído.**

### Alterações

- O worker envia cada observação de progresso para `project_queue`, com tipo de
  mensagem, ID da tarefa de origem, projeto, vídeo, token da execução, percentagem,
  indicação de pré-visualização e data/hora. Não foi criada uma fila nova.
- O serviço `projects` confirma que a tarefa ainda existe e que projeto, vídeo,
  token e execução ativa correspondem à mensagem. Percentagens inválidas,
  repetidas, antigas ou de outra execução são ignoradas.
- O progresso aceite é guardado no `processingRun` com uma atualização atómica e
  monotónica. O evento para a interface só é publicado depois da gravação.
- O consumidor confirma mensagens depois de as tratar. Se ocorrer uma falha ao
  guardar, a mensagem é devolvida à fila para nova tentativa; mensagens inválidas
  ou antigas são confirmadas e descartadas.
- As respostas finais de sucesso/erro continuam a usar o mesmo caminho. Os
  eventos de progresso de pré-visualizações sem execução ativa são ignorados, pois
  não há uma execução persistente a que possam ser associados.

### Validação

- `node --test tests/*.test.js`, em `projects/`: **24 aprovados, 0 falhados**.
  Os testes cobrem progresso aceite, repetido, antigo, cancelado, projeto/vídeo
  errado, conteúdo inválido, gravação condicional e confirmação/recolocação na
  fila.
- `.venv/bin/python -m pytest -q tests`, em `Tools/video/`: **76 aprovados**.
  Inclui o formato tipado da mensagem produzida pelo worker.
- Smoke test integrado com um vídeo de 10 segundos: o estado persistido avançou
  de `0` até `100`, e só depois passou a `completed`. O resultado final foi
  guardado normalmente e não ficaram tarefas pendentes. O projeto e os ficheiros
  criados para o teste foram removidos.
