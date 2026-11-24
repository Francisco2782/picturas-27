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

== DA-1 — Escala Limitada de Trabalhadores em Fila Única (cenário QS-01)

A decisão DA-1 concretiza a melhoria do requisito de capacidade e comportamento temporal sobre o motor de processamento de vídeo, formalizada no registo ADR da @tab-decisao-da1.

#tab([Decisão arquitetural DA-1],
  tabela-campos(
    [Contexto], [Na solução de base, o processamento de vídeo executava num único contentor `video_tool` associado à fila `video_queue` com receção unitária (`prefetch_count=1`). Tarefas pesadas de legendagem automática em CPU monopolizavam o trabalhador durante dezenas de segundos, provocando bloqueio de cabeça de fila e atrasando trabalhos subsequentes em mais de 60 segundos. A intervenção exigia aumentar a capacidade de processamento sem quebrar os contratos de despacho e preservando a integridade das operações em passagem única.],
    [Tática(s) escolhida(s)], [*TAT-01* — Replicar computação (*Replicate computation*).],
    [Estrutura / padrão que a realiza], [Padrão *Competing Consumers* (consumidores concorrentes): instanciação de duas réplicas idênticas do contentor `video_tool` a consumir da mesma fila durável `video_queue` no RabbitMQ. Cada réplica preserva estritamente `prefetch_count=1`, confirmação manual explícita (`basic_ack`) e escrita de ficheiros temporários `.part` atómicos no volume montado `image_data`.],
    [Alternativas consideradas e razão de rejeição], [*TAT-02 (Filas segregadas por tipo de carga):* Rejeitada porque exigiria reescrever a lógica de despacho do orquestrador `projects`, alterar o formato de mensagens e reconfigurar o RabbitMQ, introduzindo elevado risco de regressão. <br>*TAT-03 (Partilha de modelo em memória):* Rejeitada como solução isolada porque otimizaria apenas o carregamento do modelo Faster-Whisper, mantendo intacta a serialização forçada e a incapacidade de executar dois pedidos em paralelo.],
    [Consequências positivas], [A média do tempo de espera do lote B (`b_wait_seconds`) caiu de 61,727 s na linha de base oficial para *0,113 s* nos ensaios finais, superando com folga o valor-alvo ($<= 15$ s) e o mínimo aceitável ($<= 30$ s). O Projeto B iniciou a execução imediatamente no segundo trabalhador livre.],
    [Consequências negativas / riscos], [Aumento do pico médio agregado de RAM de 2,86 GB para *4,29 GB* (duplicação de instâncias Faster-Whisper em memória). Risco de condições de corrida no orquestrador `projects` na consolidação de lotes concorrentes, o qual foi formalmente identificado e mitigado na auditoria e no ensaio P-02.],
    [Elementos arquiteturais afetados], [`docker-compose.yaml` (escalamento de `video_tool`), RabbitMQ (`video_queue`) e orquestrador `projects/utils/processBatch.js` (sincronização de commit de lote).],
    [Origem e âmbito do _refactoring_], [Subsistema de processamento de vídeo e infraestrutura de orquestração de contentores.],
    [Classe (A/B/C)], [*Classe A* (_refactoring_ estrutural puro sem impacto visível no utilizador final).],
    [Implementação (_commits_ / _pull requests_)], [Implementação base em `8c8c6ec` e mitigação de concorrência em `67948ed` (sessão P-02).],
    [Desvios face à decisão], [O ficheiro `docker-compose.yaml` preserva 1 réplica por omissão para poupar recursos na máquina de desenvolvimento local, ativando 2 réplicas na campanha de capacidade através do comando `docker compose up -d --scale video_tool=2`.],
  ),
) <tab-decisao-da1>

== DA-2 — Persistência Atómica de Snapshot e Interface Desacoplada (cenário QS-02)

A decisão DA-2 concretiza a melhoria da usabilidade e operabilidade da interface web durante a execução de tarefas demoradas, formalizada no registo ADR da @tab-decisao-da2.

#tab([Decisão arquitetural DA-2],
  tabela-campos(
    [Contexto], [Na solução herdada da Fase 1, o acionamento de um lote no frontend ativava uma janela modal sobreposta (*overlay*) que bloqueava toda a interação do utilizador com o dashboard. Além disso, o progresso da execução residia apenas no estado interno do componente React: qualquer mudança de página ou recarregamento acidental (_refresh_ F5) destruía o estado visual, deixando o utilizador sem saber se o lote continuava em execução, se tinha falhado ou se já havia terminado.],
    [Tática(s) escolhida(s)], [*TAT-04* (Manter cópias de dados: snapshot atómico no MongoDB), *TAT-05* (Desacoplamento visual da interface) e *TAT-06* (Reconciliação e sincronização de eventos cliente-servidor).],
    [Estrutura / padrão que a realiza], [Padrão *Snapshot* atómico no MongoDB através do subdocumento `processingRun` no modelo do projeto; disponibilização de rota REST autenticada de consulta segura (`GET /projects/:owner/:project/processing-status`); eliminação do modal obstrutivo e substituição por uma barra de progresso flutuante persistente no layout comum do Dashboard Next.js; sincronização combinada entre eventos push via Socket.IO e chamadas de reconciliação de estado com debounce.],
    [Alternativas consideradas e razão de rejeição], [*Armazenamento em LocalStorage/SessionStorage no browser:* Rejeitada por limitar o acompanhamento a uma única aba e perder o contexto se o utilizador fechar o navegador ou aceder noutro dispositivo. <br>*Comunicação exclusiva por WebSocket sem persistência no backend:* Rejeitada porque a desconexão ou recarregamento de página quebra a sessão Socket.IO, mantendo a interface desatualizada até à eventual chegada de um novo evento emitido pelo trabalhador.],
    [Consequências positivas], [Pleno sucesso na validação experimental no Chromium: *12/12 ações concluídas (100%)*, taxa de recuperação de *3/3 após navegação*, *3/3 após recarregamento* e *3/3 após reconexão de rede*, com zero conclusões prematuras. O utilizador pode navegar livremente e editar outros projetos enquanto o lote de vídeo é processado.],
    [Consequências negativas / riscos], [Introdução de escritas atómicas na base de dados a cada avanço relevante de progresso e acréscimo de pedidos HTTP à rota de estado durante execuções ativas (medidos em 4 chamadas adicionais e 1048 bytes num intervalo de 4 segundos a 1 Hz).],
    [Elementos arquiteturais afetados], [`projects/models/project.js`, `projects/routes/projects.js`, `projects/utils/processingRun.js`, `apiGateway/routes/projects.js`, `frontend/app/dashboard/` e `frontend/components/`.],
    [Origem e âmbito do _refactoring_], [Interação e fronteira de comunicação entre o orquestrador backend e o frontend SPA em Next.js.],
    [Classe (A/B/C)], [*Classe B* (alteração visual na interface que constitui o objeto direto do requisito de usabilidade/operabilidade, sem criação de novas funcionalidades de edição).],
    [Commits e referências de implementação], [Implementação do modelo e endpoint em `ed20df4`, componentes visuais em `0f6dbc5` e endurecimento em `24c1266`.],
    [Desvios face ao desenho original], [Ajustada a lógica de primeira visita a estados terminais para evitar alertas espúrios após a conclusão do lote e integrados controlos de autorização para restringir o cancelamento a utilizadores com permissões adequadas (evitando o defeito F8).],
  ),
) <tab-decisao-da2>
