#import "../template.typ": *

= Âmbito e Vista da Arquitetura

#orientacao[
  *Origem:* Exercício 6, Bloco 1, secções 0 e 1 do _template_ (preparação, fontes, vista global e sequência).

  *Objetivo do capítulo:* situar o leitor. Mostra como a solução foi lançada, em que fontes se baseia a análise e como é
  a arquitetura da solução de base, com o caminho do vídeo em destaque. É a base factual dos capítulos seguintes.

  *Foco:* a *extensão de vídeo, enquadrada no padrão global* da solução. Não analisem o vídeo isoladamente: o que o vídeo
  faz só se percebe à luz do que a solução faz como um todo.

  *Rigor:* cada afirmação sobre o sistema atual cita uma evidência (`EV-nn`) ou é assumida como hipótese (`H-nn`). A
  secção 2.4 explica como se escreve uma evidência.
]

== Preparação e ambiente

#orientacao[
  Registem como a solução foi lançada, para que outra pessoa a consiga repetir e obtenha o mesmo resultado. Indiquem
  sempre o _commit_ de partida (o mesmo em todos os capítulos), os comandos exatos e o ambiente de execução. Se algum
  passo falhou ou exigiu um ajuste, escrevam-no: é informação útil para quem repetir o processo.

  A descrição do processamento em lote que se segue à tabela deve ser escrita pela equipa, com palavras próprias, e
  mostrar que perceberam o fluxo completo, do _Apply_ ao resultado, para imagens e vídeos.
]

Para garantir a reprodutibilidade integral das observações, dos testes e das medições empíricas, a solução foi instanciada em ambiente controlado a partir do repositório oficial, registando-se as versões de software e as especificações de hardware descritas na @tab-preparacao-ambiente.

#tab([Preparação e ambiente],
  tabela-campos(
    [Commit de partida], [`052310226c51fa57a17101c7bd1ad795674aac95` (tag `phase2-base`), checkout `afb84e5c818820f807bb504a8ed9f0a3162cc9dd` em `picturas-um/picturas-27`],
    [Comandos de arranque], [Arranque padrão: `docker compose up -d --build`. Escala para duas réplicas no ensaio de capacidade: `docker compose up -d --no-build --scale video_tool=2 video_tool`],
    [Ambiente (SO, CPU, RAM, versões de Docker e Compose)], [Linux 7.0.0-43-generic x86_64, processador Intel Core i7-13650HX (20 CPUs lógicas), 33,36 GB disponíveis ao Docker, Docker Engine v29.9.3 e Docker Compose v5.7.1.],
    [Projetos e amostras de dados], [Capacidade: Projeto A com vídeo com fala longa de 177 s em 1080p (`speech_mandela_177s_1080p.webm`) com legendagem; Projeto B com dois ficheiros de 10 s em 720p (`sample_10s_720p.mp4`) e um de 6 s (`sample_6s.mov`) com brilho. Usabilidade: Projeto A com excerto de fala de 10 s com legendas; Projeto B para navegação na barra de ferramentas.],
    [Problemas e notas de arranque], [Conflitos com volumes legados do SeaweedFS da Fase 1 exigiram limpeza forçada (`docker compose down -v --remove-orphans`) devido a alterações estruturais de armazenamento; comunicação TLS interna com certificados autoassinados expirados necessitando de bypass `rejectUnauthorized: false`.],
  ),
) <tab-preparacao-ambiente>

*Como é orquestrado o processamento em lote de imagens e de vídeos:*

NOTA: REVER PORQUE ERA SUPOSTO SER DE 5 A 8 LINHAS

O utilizador aciona o processamento no frontend através do botão `Apply`, enviando uma chamada HTTP a `POST /api-gateway/projects/:user/:project/process`. O serviço `projects` atua como orquestrador central e inspeciona o tipo de cada elemento multimédia (`media_type`). Para cada imagem, o orquestrador publica uma mensagem individual por ferramenta na respetiva fila e aguarda a confirmação de conclusão na `project_queue` antes de despachar a ferramenta seguinte da cadeia. Para cada vídeo, o orquestrador encapsula todo o pipeline de operações numa única mensagem e publica-a na fila comum `video_queue`. Os efeitos de fotograma contíguos partilham uma única passagem de descodificação e codificação. Operações especializadas (como legendas ou extração de fotogramas) integram-se como etapas adicionais da cadeia. O _worker_ reporta o progresso de execução e o estado terminal para a `project_queue`. O orquestrador persiste as atualizações aceites e retransmite-as via `ws_queue` para o `wsGateway`, que notifica o navegador em tempo real; cada operação abre e fecha uma ligação AMQP própria (`EV-10`: `projects/utils/rabbit_mq.js:11-30` — terminação forçada por `setTimeout(500)`).

== Fontes consultadas

#orientacao[
  Listem os documentos e o código que sustentam a análise, com a versão ou a data de cada um (_commit_, número de versão,
  data de acesso) e para que foram usados. Isto permite ao leitor perceber de onde vêm as afirmações e detetar
  fontes desatualizadas. Incluam os documentos de apoio da unidade curricular que influenciaram a análise.
]

A análise estrutural do sistema e o diagnóstico arquitetural fundamentaram-se nas fontes técnicas e documentais enumeradas na @tab-fontes-consultadas.

#tab([Fontes consultadas],
  tabela(
    colunas: (5.2cm, 3.4cm, 1fr),
    [Fonte], [Versão / data], [Usada para],
    [`README.md`, `AGENTS.md`], [Commit `0f6dbc5`], [Topologia de serviços, convenções operacionais, instruções de arranque,  mapeamento de portas e restrições de bifurcação imagem/vídeo.],
    [`doc-ext-requisitos-2627.pdf`], [PL1-G4 (2026)], [Especificação de requisitos funcionais e não funcionais herdados da extensão de vídeo da Fase 1 (`REQ-VID-*`).],
    [`doc-sol-arquitetural.pdf`], [Fase 1 (2026)], [Documento de arquitetura herdada com descrição dos padrões originais de imagem.],
    [Slides das aulas teóricas e suporte], [Novembro de 2026], [Taxonomia de estilos arquiteturais (Camadas, Microsserviços, Event-Driven, Pipes & Filters) e táticas de desenho de software (Bass et al.).],
    [Diretrizes da Fase 2 (`fase-2-guidelines.md`)], [Versão 1], [Regras de refactoring, restrições metodológicas e critérios de aceitação.],
    [Arquivo de evidência D-01], [Medições de 17 e 22–23/11/2026], [Versões do ambiente, métricas, eventos e condições dos ensaios.],
  ),
) <tab-fontes-consultadas>

== Vista da arquitetura global

#orientacao[
  A vista mostra o *padrão global* da solução (serviços, filas, armazenamento, fronteiras) com o *caminho do vídeo
  destacado*, de modo a que se veja onde o vídeo segue o resto do sistema e onde se afasta dele.

  Usem a notação e a ferramenta que preferirem (C4 de contentores, componentes UML, PlantUML, Mermaid, draw.io), mas
  incluam sempre uma *legenda* e indiquem a ferramenta. O diagrama tem de ser legível no documento impresso e
  consistente com o que foi observado na solução em execução, não apenas com a documentação.
]

A arquitetura global do PictuRAS estrutura-se em *Microsserviços Orientados a Eventos* (*Event-Driven Microservices*), complementado por uma camada perimetral de acesso e despacho (Nginx + API Gateway + WebSocket Gateway), orquestramento de mensagens assíncrono com RabbitMQ e persistência desacoplada (MongoDB + SeaweedFS S3 + volume de ficheiros `image_data`). a @fig-arquitetura-global, destaca-se a laranja o caminho percorrido pelo processamento de vídeo.

#figure(
  image("../images/arquitetura_global_plantuml.svg", width: 95%),
  caption: [Vista da arquitetura global com o caminho do vídeo destacado],
) <fig-arquitetura-global>

*Ferramenta / notação:*  PlantUML / C4 Component View adaptada com estereótipos explícitos de comunicação e codificação por cores (`arquitetura_global.puml`).

#tab([Legenda da vista da arquitetura global],
  tabela(
    colunas: (5.5cm, 1fr),
    [Elemento (cor, forma ou estilo)], [Significado],
    [Retângulo Laranja (`#FDE7D3` / seta `#C2410C`)], [Caminho e componentes dedicados ao processamento de vídeo (`video_queue`, `video_tool`).],
    [Retângulo Cinza / Azul claro], [Camada perimetral de acesso (Nginx, API Gateway REST e WebSocket Gateway).],
    [Retângulo Branco (`business`)], [Serviços centrais de negócio (`projects`, `users`, `subscriptions`, `imageStorageService`).],
    [Fila Amarela / Castanho (`rmq`)], [Filas duráveis geridas pelo _broker_ RabbitMQ (`<tool>_queue`, `project_queue`, `ws_queue`, `video_queue`).],
    [Linha Tracejada Roxa (`#4F46E5`)], [Acesso ao volume partilhado no sistema de ficheiros local (`image_data`).],
    [Cilindro Amarelo], [Bases de dados dedicadas (MongoDB) e _Object Storage_ compatível com S3 (SeaweedFS).],
  ),
)

== Sequência de um pedido completo

#orientacao[
  Descrevam, passo a passo, o que acontece num pedido completo para um projeto com vídeos: carregamento → definição do
  _pipeline_ → _Apply_ → progresso → resultado. O diagrama de sequência mostra a ordem das interações; a tabela
  identifica, para cada passo, quem fala com quem e através de que mensagem, _endpoint_ ou fila.

  *O que é uma evidência (`EV-nn`).* Uma evidência é a referência *verificável* que sustenta uma afirmação sobre o
  sistema atual. Deve permitir que outra pessoa, no _commit_ de partida, confirme o que afirmam sem ter de adivinhar.
  Pode ser:
  - *código*, com ficheiro e linhas (e.g., `video.py:8-9`);
  - *configuração*, com ficheiro e linha (e.g., `docker-compose.yml`, definição de uma fila ou de um volume);
  - *mensagem* observada (e.g., conteúdo de uma mensagem na fila, resposta de um _endpoint_);
  - *medição* ou *registo de execução*, com o comando usado e o resultado;
  - *documento*, com a secção (e.g., `doc-sol-arquitetural.pdf`, secção 3).

  Regras: o ID é sequencial (`EV-01`, `EV-02`, …), único, e nunca se reutiliza. Como o relatório não tem um registo
  separado, *descrevam a evidência no sítio onde a usam pela primeira vez* (formato: `EV-nn`: localização — o que
  mostra); nas ocorrências seguintes basta o ID. Uma afirmação sem evidência não é um facto: marquem-na como
  *hipótese* (`H-nn`) e indiquem como a confirmar ou refutar.
]
O processamento de um projeto com ficheiros de vídeo estrutura-se em cinco fases essenciais: carregamento dos ficheiros multimédia, configuração ordenada do pipeline, submissão em lote (_Apply_), acompanhamento de progresso em tempo real e consolidação final de resultados. A ordem temporal das interações encontra-se representada na @fig-sequencia-pedido e detalhada passo a passo na @tab-passos-pedido.

#figure(
  image("../images/sequencia_pedido.svg", width: 95%),
  caption: [Sequência do processamento em lote de um projeto com vídeos],
) <fig-sequencia-pedido>

#tab([Passos do pedido completo de vídeo],
  tabela(
    colunas: (2.8cm, 3.4cm, 1fr, 3.8cm),
    [Passo], [Origem $->$ Destino], [Mensagem / _endpoint_ / fila], [Evidência],
    [Carregamento do vídeo], [Browser $->$ Gateway $->$ `projects` $->$ S3], [`POST /api-gateway/projects/:owner/:project/video` (multipart/form-data)], [`EV-01`: `projects/routes/projects.js:1564-1671` e `projects/utils/video.js:14-80` — o orquestrador despacha imagens passo a passo e vídeos em mensagem única para `video_queue`, e valida contentor, codec de vídeo, duração, resolução e limites de quota via ffprobe.],
    [Definição do _pipeline_], [Browser $->$ Gateway $->$ `projects`], [`POST …/tool` (adicionar) e `POST …/reorder` (reordenar)], [`EV-01`: `apiGateway/routes/projects.js` e controladores em `projects/routes/projects.js`. Atualiza a coleção do projeto no MongoDB.],
    [Submissão (_Apply_)], [Browser $->$ Gateway $->$ `projects` $->$ RabbitMQ], [`POST /api-gateway/projects/:user/:project/process` $->$ publicação na fila `video_queue`], [`EV-02`: `Tools/video/video.py:54, 140, 170, 174` — `prefetch_count=1`, modelo síncrono bloqueante e confirmação manual (`basic_ack`) no fim do processamento; `EV-01`: `projects/utils/processBatch.js:88-142` despacha 1 mensagem por vídeo com pipeline integral.],
    [Progresso], [`video_tool` $->$ `project_queue` $->$ `projects` $->$ `ws_queue` $->$ UI], [Eventos `video-progress` tipados com token e percentagem], [`EV-03`: `Tools/video/subtitles.py:15-21, 60-63` — legendagem com Faster-Whisper síncrono em CPU/int8; `EV-04`: `projects/models/project.js:35-65` e `projects/utils/processingRun.js` — subdocumento `processingRun` com snapshot atómico, token, estado terminal e progresso monotónico. O orquestrador valida e persiste o snapshot antes de notificar o WebSocket; consultável em `GET …/processing-status` (`EV-05`: `projects/routes/projects.js`, `apiGateway`).],
    [Consolidação de resultados], [`video_tool` $->$ `project_queue` $->$ `projects` $->$ UI], [Mensagem de conclusão na `project_queue`, confirmação manual (`ack`), commit e `process-update`], [`EV-02`, `EV-04`: criação atómica de registos `Result` no MongoDB e guarda do ficheiro final no S3. O ensaio P-02 confirmou a integridade de dois resultados simultâneos; a hipótese `H-01` (condições de corrida entre trabalhadores paralelos no fecho do lote no MongoDB, avaliada por injeção de finalizações concorrentes com barreiras temporais) foi confirmada na auditoria e corrigida nessa prova.],
  ),
) <tab-passos-pedido>


NOTA: REVER SE ESTE TOPICO É AQUI OU NOUTRO CAPITULO

== Onde e porquê o sistema bifurca entre imagem e vídeo

Embora a aplicação procure oferecer uma experiência unificada na interface, a realidade física e computacional do processamento de vídeo obrigou a bifurcações profundas na orquestração e na execução interna, resumidas na @tab-bifurcacao-media.

#tab([Pontos de bifurcação entre o caminho de imagens e o caminho de vídeo],
  tabela(
    colunas: (2.4cm, 3.2cm, 3.2cm, 1fr),
    tamanho: 8.5pt,
    [Ponto de bifurcação], [Caminho de imagens], [Caminho de vídeo], [Fundamentação arquitetural (facto / hipótese)],
    [Validação e Upload], [`POST …/img` (validação rápida de formato raster PNG/JPEG).], [`POST …/video` (inspeção minuciosa de codecs, streams de áudio/vídeo, resolução e duração via ffprobe).], [Facto (`EV-01`): Ficheiros de vídeo possuem dimensões temporais e restrições rigorosas de compatibilidade inexistentes em imagens estáticas.],
    [Despacho no Orquestrador], [Despacho granular passo a passo: 1 mensagem por cada par (imagem, ferramenta) enviada para `<tool>_queue`.], [Despacho em bloco: 1 mensagem por vídeo com todo o pipeline enviada para `video_queue`.], [Facto (`EV-01`): Evitar o custo incomportável de descodificar e recodificar ficheiros de vídeo pesados a cada filtro sequencial.],
    [Execução nos Trabalhadores], [Microsserviços PIL/IA autónomos e especializados (16 contentores dedicados).], [Serviço `video_tool` que concentra todos os filtros num único trabalhador.], [Facto (`EV-02`, `EV-06`: `docker-compose.yaml:255-260` — serviço `video_tool` com uma única réplica por omissão): Os efeitos de fotograma contíguos partilham uma passagem em memória, reduzindo overhead de disco e CPU.],
    [Confirmação AMQP (_Ack_)], [Confirmação automática imediata na receção (`auto_ack=True`).], [Confirmação manual explícita (`ack`) no fim do processamento ou falha tratada.], [Facto (`EV-02`, `EV-07`: `Tools/utils/rabbit_mq.py:28-35` — trabalhadores de imagem usam `auto_ack=True`): Como o processamento de vídeo é demorado, o auto-ack perderia tarefas se o trabalhador falhasse a meio da execução.],
    [Interface de Utilizador], [Ferramentas de IA (remoção de fundo, super-resolução) e exportação em PDF ativas.], [Filtros de IA e PDF ocultos; filtros exclusivos de vídeo (`trim`, `speed`, `subtitles`).], [Facto (`EV-08`: `frontend/app/dashboard/[pid]/page.tsx` — estado de progresso em memória volátil do componente React e modal bloqueante durante o lote): Os modelos atuais de IA de imagem do sistema não processam sequências temporais e vídeo não é convertível em PDF.],
  ),
) <tab-bifurcacao-media>
