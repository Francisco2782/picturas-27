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
    [Contexto], [Uma legendagem longa ocupa o único consumidor e atrasa trabalhos curtos.],
    [Tática(s) escolhida(s)], [TAT-01, replicar a computação.],
    [Estrutura / padrão que a realiza], [Duas réplicas de `video_tool` consomem `video_queue` no ensaio, cada uma com `prefetch_count=1` e confirmação manual.],
    [Alternativas consideradas e razão de rejeição], [TAT-02 exigiria alterar o despacho. TAT-03 reduziria o carregamento do modelo e manteria a serialização.],
    [Consequências positivas], [Na campanha final da revisão `3cb1b74`, a espera média de B foi 0,123 s. A campanha anterior registou 0,113 s.],
    [Consequências negativas / riscos], [Maior pico de memória e risco de fechos simultâneos.],
    [Elementos arquiteturais afetados], [Escala no Compose e publicação de resultados em `projects/utils/processBatch.js`.],
    [Origem e âmbito do _refactoring_], [Implantação do worker e integridade da publicação do lote.],
    [Classe (A/B/C)], [A. Preserva o contrato de processamento.],
    [Implementação (_commits_ / _pull requests_)], [Revisão `8c8c6ec` e regressão P-02 em `67948ed`.],
    [Desvios face à decisão], [Compose usa uma réplica por omissão. A campanha dedicada usa duas.],
  ),
)

== DA-2 — Estado de execução persistido e interface navegável (QS-02)

#tab([Decisão arquitetural DA-2],
  tabela-campos(
    [Contexto], [O acompanhamento dependia do estado React e de um overlay. O recarregamento perdia o progresso visível.],
    [Tática(s) escolhida(s)], [TAT-04, snapshot. TAT-05, interface desacoplada. TAT-06, reconciliação de eventos.],
    [Estrutura / padrão que a realiza], [`processingRun` no MongoDB, rota autenticada e painel do dashboard sincronizado por Socket.IO e polling.],
    [Alternativas consideradas e razão de rejeição], [O armazenamento exclusivo no browser limita a recuperação a esse cliente. Uma solução exclusivamente WebSocket depende da chegada de outro evento após a ligação.],
    [Consequências positivas], [12/12 ações e recuperação em 3/3 por percurso verificado.],
    [Consequências negativas / riscos], [Escritas e consultas adicionais durante a execução.],
    [Elementos arquiteturais afetados], [`projects`, `apiGateway` e dashboard Next.js.],
    [Origem e âmbito do _refactoring_], [Interação entre o orquestrador e o browser.],
    [Classe (A/B/C)], [B. A mudança da interface é a intervenção de operabilidade prevista pelo cenário.],
    [Implementação (_commits_ / _pull requests_)], [Revisões `ed20df4`, `0f6dbc5` e `24c1266`.],
    [Desvios face à decisão], [F5 ajustou a primeira visita a estados terminais e o cancelamento por permissão.],
  ),
)
