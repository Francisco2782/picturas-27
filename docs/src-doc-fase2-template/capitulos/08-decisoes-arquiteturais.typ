#import "../template.typ": *

= Decisões Arquiteturais

#orientacao[
  *Origem:* Exercício 7, secção 3 do _template_.

  Uma decisão por cenário (`DA-1` para `QS-01`, `DA-2` para `QS-02`). Cada decisão é um pequeno registo, ao estilo ADR: o
  contexto, a tática escolhida, a estrutura ou padrão que a realiza, as alternativas consideradas e a razão da sua
  rejeição, as consequências positivas e negativas, e os elementos arquiteturais afetados.

  Só vale a pena registar uma decisão se havia *alternativas reais* (as táticas do capítulo 7 que não foram escolhidas).
  Justifiquem a escolha pelo cenário e pelas restrições da fase: rejeitem as táticas de classe C, porque a fase é de
  _refactoring_, e avaliem o risco de regressão do âmbito da alteração.

  *Depois de implementada*, completem cada decisão com as referências da implementação (_commits_ ou _pull requests_ no
  repositório entregue) e com os desvios face ao que foi decidido, explicando porquê. A vista «depois» do capítulo 9
  deve corresponder ao que foi efetivamente implementado.
]

== DA-1 — Consumidores concorrentes na fila de vídeo (QS-01)

#tab([Decisão arquitetural DA-1],
  tabela-campos(
    [Contexto], [Na baseline (`0523102`), uma legendagem longa em CPU (`EV-05`) ocupa o único consumidor de `video_queue` (`EV-04`, `EV-08`), bloqueando trabalhos curtos submetidos em paralelo.],
    [Tática(s) escolhida(s)], [TAT-01: introduzir concorrência mantendo múltiplas cópias de computação.],
    [Estrutura / padrão que a realiza], [Padrão de consumidores concorrentes (ALT-1): duas réplicas homogéneas de `video_tool` consomem `video_queue` no ensaio de capacidade, mantendo `prefetch_count=1` e confirmação manual após resposta terminal.],
    [Alternativas consideradas e razão de rejeição], [TAT-02 (filas por carga) alteraria a topologia de despacho e `rabbitMQ/definitions.json`; TAT-03 (partilha de modelo) reduziria memória de arranque mas manteria a serialização em fila. Nenhuma tática de classe C foi considerada.],
    [Consequências positivas], [Elimina o bloqueio de cabeça de fila para cargas concorrentes: a espera média de B desceu de 61,727 s para 0,123 s (`3cb1b74`).],
    [Consequências negativas / riscos], [Aumento do pico agregado de RAM (2,86 GB para 4,25 GB) e risco de condição de corrida no fecho concorrente de lotes (`H-01`), mitigado por atualização condicional atómica no orquestrador (tática de prevenção de falhas por transação).],
    [Elementos arquiteturais afetados], [Escala do serviço `video_tool` no Compose, limpeza de ficheiros temporários por saída e publicação/fecho do lote em `projects/utils/processBatch.js` e `projects/routes/projects.js`.],
    [Origem e âmbito do _refactoring_], [Implantação do trabalhador de vídeo e integridade do fecho no orquestrador, mantendo inalterado o contrato de mensagens.],
    [Classe (A/B/C)], [A — _refactoring_ puro que preserva o comportamento externo e o contrato de processamento.],
    [Implementação (_commits_ / _pull requests_)], [Revisão `8c8c6ec` e regressão P-02 em `67948ed` (com seguimento de recuperação em `3cb1b74`).],
    [Desvios face à decisão], [O `docker-compose.yaml` conserva uma réplica por omissão para conter o consumo base de RAM; a campanha de capacidade escala explicitamente para duas réplicas (`--scale video_tool=2`).],
  ),
)

== DA-2 — Estado de execução persistido e interface navegável (QS-02)

#tab([Decisão arquitetural DA-2],
  tabela-campos(
    [Contexto], [O acompanhamento dependia do estado volátil em React e de um _overlay_ bloqueante (`EV-10`), perdendo visibilidade perante navegação ou recarregamento (F5).],
    [Tática(s) escolhida(s)], [TAT-04 (persistir _snapshot_), TAT-05 (desacoplar painel global) e TAT-06 (reconciliar eventos).],
    [Estrutura / padrão que a realiza], [Combinação de modelo centrado em estado persistido (`processingRun` no MongoDB) com padrão _Observer_ / _Publish-Subscribe_ (Socket.IO via `ws_queue`) e reconciliação por consulta autenticada à rota de estado (`EV-06`, `EV-07`).],
    [Alternativas consideradas e razão de rejeição], [`TAT-07` restringiria a recuperação ao mesmo browser e poderia repor um estado antigo. `TAT-08` obrigaria a aguardar um novo evento após a reconexão.],
    [Consequências positivas], [Permite edição paralela sem bloqueio (12/12 ações) e garante recuperação consistente após navegação, recarregamento e reconexão (3/3 por percurso, zero falsas conclusões).],
    [Consequências negativas / riscos], [Escritas adicionais de progresso em MongoDB e pedidos HTTP extras de consulta de estado durante a execução.],
    [Elementos arquiteturais afetados], [`projects` (persistência e rota de estado), `apiGateway` (encaminhamento autenticado) e frontend Next.js (painel global no layout do dashboard).],
    [Origem e âmbito do _refactoring_], [Interação entre o orquestrador e o browser, desacoplando a apresentação do ciclo de execução.],
    [Classe (A/B/C)], [B — a alteração da interface é a melhoria visível de operabilidade prevista pelo cenário `QS-02`, sem adicionar funcionalidades.],
    [Implementação (_commits_ / _pull requests_)], [Revisões `ed20df4`, `0f6dbc5` e `24c1266`.],
    [Desvios face à decisão], [Na validação final, ajustou-se a primeira visita a estados terminais e o controlo de permissões no cancelamento.],
  ),
)

