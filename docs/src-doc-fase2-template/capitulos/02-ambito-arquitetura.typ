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

#tab([Preparação e ambiente],
  tabela-campos(
    [Commit de partida], [`052310226c51fa57a17101c7bd1ad795674aac95` (tag `phase2-base`), checkout `afb84e5c818820f807bb504a8ed9f0a3162cc9dd`],
    [Comando(s) de arranque], [`docker compose up -d --build` (e escala com `docker compose up -d --no-build --scale video_tool=2 video_tool`)],
    [Ambiente (SO, CPU, RAM, versões de Docker e Compose)], [Linux 7.0.0-43-generic x86_64, i7-13650HX, 20 CPUs lógicos, cerca de 33,36 GB disponíveis ao Docker, Engine 29.9.3 e Compose 5.7.1. Os manifestos registam as diferenças entre as campanhas.],
    [Projetos de teste e amostras], [Capacidade: A usa `speech_mandela_177s_1080p.webm`; B usa dois `sample_10s_720p.mp4` e um `sample_6s.mov`, em `samples/video/`. Operabilidade: amostra local de 10 s com fala.],
    [Problemas e notas de arranque], [Necessidade de `docker compose down -v --remove-orphans` ao migrar volumes legados do SeaweedFS (S3); certificados TLS internos com bypass `rejectUnauthorized: false`],
  ),
)

*Como é orquestrado o processamento em lote de imagens e de vídeos* (5 a 8 linhas):

O botão `Apply` envia um pedido a `POST /api-gateway/projects/:user/:project/process`. Para cada imagem, o orquestrador envia uma mensagem por ferramenta à fila respetiva e avança quando recebe a resposta na `project_queue`. Para cada vídeo, identificado por `media_type`, envia o pipeline completo numa mensagem à `video_queue`. Os efeitos de fotograma contíguos partilham uma passagem de descodificação e codificação. As legendas podem introduzir etapas adicionais e a extração de fotogramas produz imagens. O worker publica progresso e resultados em `project_queue`. O orquestrador guarda o progresso aceite e publica as atualizações em `ws_queue`.

== Fontes consultadas

#orientacao[
  Listem os documentos e o código que sustentam a análise, com a versão ou a data de cada um (_commit_, número de versão,
  data de acesso) e para que foram usados. Isto permite ao leitor perceber de onde vêm as afirmações e detetar
  fontes desatualizadas. Incluam os documentos de apoio da unidade curricular que influenciaram a análise.
]

#tab([Fontes consultadas],
  tabela(
    colunas: (5.5cm, 3.2cm, 1fr),
    [Fonte], [Versão / data], [Usada para],
    [`README.md`, `AGENTS.md`], [Commit `0f6dbc5` ], [Instruções de arranque, portas, topologia de serviços, convenções e regras de bifurcação imagem/vídeo.],
    [`doc-ext-requisitos-2627.pdf`], [PL1-G4 (2026)], [Requisitos funcionais e não funcionais herdados da extensão de vídeo da Fase 1 (`REQ-VID-*`).],
    [`doc-sol-arquitetural.pdf`], [por confirmar], [Documento referido, ausente da árvore auditada.],
    [Slides da aula 11 (_Arch. Styles_) e documento de apoio de padrões arquiteturais], [2026-11-04], [Taxonomia de estilos arquiteturais (Camadas, Monolítico, Microserviços, Event-Driven, Pipeline).],
    [Diretrizes da Fase 2 (`fase-2-guidelines.md`)], [Versão 1 / 04-11-2026], [Regras de refactoring, restrições metodológicas e critérios de aceitação.],
    [Arquivo de evidência D-01], [Medições de 17 e 22–23/11/2026], [Versões do ambiente, métricas, eventos e condições dos ensaios.],

  ),
)

== Vista da arquitetura global

#orientacao[
  A vista mostra o *padrão global* da solução (serviços, filas, armazenamento, fronteiras) com o *caminho do vídeo
  destacado*, de modo a que se veja onde o vídeo segue o resto do sistema e onde se afasta dele.

  Usem a notação e a ferramenta que preferirem (C4 de contentores, componentes UML, PlantUML, Mermaid, draw.io), mas
  incluam sempre uma *legenda* e indiquem a ferramenta. O diagrama tem de ser legível no documento impresso e
  consistente com o que foi observado na solução em execução, não apenas com a documentação.
]

A arquitetura global do PictuRAS estrutura-se como um sistema de microsserviços orientados a eventos, dispondo de uma camada perimetral de acesso (Nginx + API Gateway + WebSocket Gateway) e orquestração assíncrona suportada pelo _broker_ RabbitMQ e persistência desacoplada (MongoDB + SeaweedFS S3 + volume de ficheiros `image_data`). Na @fig-arquitetura-global, destaca-se a laranja o caminho percorrido pelo processamento de vídeo.

#figure(
  image("../images/arquitetura_global_plantuml.svg", width: 95%),
  caption: [Vista da arquitetura global com o caminho do vídeo destacado],
) <fig-arquitetura-global>

*Ferramenta / notação:* PlantUML / C4 Component View adaptada com codificação por cores e estereótipos de comunicação (`arquitetura_global.puml`).

#tab([Legenda da vista da arquitetura global],
  tabela(
    colunas: (5.5cm, 1fr),
    [Elemento (cor, forma ou estilo)], [Significado],
    [Retângulo Laranja (`#FDE7D3` / seta `#C2410C`)], [Caminho e componentes dedicados ao processamento de vídeo (`video_queue`, `video_tool`).],
    [Retângulo Cinza / Azul claro], [Camada perimetral de acesso (Nginx), API Gateway e frontend Next.js SPA.],
    [Retângulo Branco (`business`)], [Serviços de negócio (`projects`, `users`, `subscriptions`, `imageStorageService`).],
    [Fila Amarela / Castanho (`rmq`)], [Filas duráveis do _broker_ RabbitMQ (`<tool>_queue`, `project_queue`, `ws_queue`, `video_queue`).],
    [Linha Tracejada Roxa (`#4F46E5`)], [Acesso ao volume partilhado de ficheiros no sistema de ficheiros local (`image_data`).],
    [Cilindro Amarelo], [Bases de dados dedicadas por serviço (MongoDB) e _Object Storage_ compatível com S3 (SeaweedFS).],
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

O processamento completo de um projeto com vídeos articula-se em cinco fases essenciais, ilustradas na @fig-sequencia-pedido e detalhadas na @tab-passos-pedido.

#figure(
  image("../images/sequencia_pedido.svg", width: 95%),
  caption: [Sequência do processamento em lote de um projeto com vídeos],
) <fig-sequencia-pedido>

#tab([Passos do pedido completo de vídeo],
  tabela(
    colunas: (2.8cm, 3.4cm, 1fr, 3.8cm),
    [Passo], [Origem → Destino], [Mensagem / _endpoint_ / fila], [Evidência],
    [Carregamento do vídeo], [Browser → Gateway → `projects` → S3], [`POST /api-gateway/projects/:owner/:project/video` (multipart/form-data)], [`EV-04`: `projects/routes/projects.js` e `projects/utils/video.js` — validam contentor, codec de vídeo, duração, tamanho e resolução.],
    [Definição do _pipeline_], [Browser → Gateway → `projects`], [`POST …/tool` para adicionar e `POST …/reorder` para reordenar], [`EV-04`: `apiGateway/routes/projects.js` e `projects/routes/projects.js`.],
    [_Apply_], [Browser → Gateway → `projects` → RabbitMQ], [`POST /api-gateway/projects/:user/:project/process` → publica em `video_queue`], [`EV-01`: `Tools/video/video.py:53-54` e `EV-04`: `projects/utils/processBatch.js:88-142` — 1 msg por vídeo com pipeline integral.],
    [Progresso], [`video_tool` → `project_queue` → `projects` → `ws_queue`], [Eventos de progresso. Na revisão final, o orquestrador aceita e persiste o progresso antes da publicação.], [EV-06, `projects/models/project.js` e `projects/utils/processingRun.js`. O snapshot é consultável pela rota `processing-status` (EV-10, rotas de `apiGateway` e `projects`).],
    [Resultado], [`video_tool` → `project_queue` → `projects` → UI], [Mensagem de sucesso, ack manual, criação de `Result` e evento `process_completed`], [EV-01 e `projects/utils/processBatch.js`. P-02 verificou dois resultados descarregáveis após fecho simultâneo.],
  ),
) <tab-passos-pedido>
