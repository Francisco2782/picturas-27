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

As observações, os testes e as medições foram registados no ambiente descrito na @tab-preparacao-ambiente. O arquivo de evidências inclui as revisões de código, as amostras e os registos dos ensaios. A reprodução da baseline depende da reconstrução da imagem do _worker_ e do protocolo de navegador arquivado (`evaluation/phase2-reproduction.md`).

#tab([Preparação e ambiente],
  tabela-campos(
    [Commit de partida], [`052310226c51fa57a17101c7bd1ad795674aac95` (tag `phase2-base`) e checkout de medição `afb84e5c818820f807bb504a8ed9f0a3162cc9dd`, no repositório de origem `picturas-um/picturas-27`],
    [Comandos de arranque], [Arranque padrão: `docker compose up -d --build`. Escala para duas réplicas no ensaio de capacidade: `docker compose up -d --no-build --scale video_tool=2 video_tool`],
    [Ambiente (SO, CPU, RAM, versões de Docker e Compose)], [Linux 7.0.0-43-generic x86_64, processador Intel Core i7-13650HX (20 CPUs lógicas), 33,36 GB disponíveis ao Docker, Docker Engine v29.9.3 e Docker Compose v5.7.1.],
    [Projetos e amostras de dados], [Capacidade: Projeto A com vídeo com fala longa de 177 s em 1080p (`speech_mandela_177s_1080p.webm`) com legendagem; Projeto B com dois ficheiros de 10 s em 720p (`sample_10s_720p.mp4`) e um de 6 s (`sample_6s.mov`) com brilho. Usabilidade: Projeto A com excerto de fala de 10 s com legendas; Projeto B para navegação na barra de ferramentas.],
    [Problemas e notas de arranque], [Conflitos com volumes legados do SeaweedFS da Fase 1 exigiram limpeza forçada (`docker compose down -v --remove-orphans`) devido a alterações estruturais de armazenamento; a validação TLS interna está desativada (`rejectUnauthorized: false`) e os certificados estavam expirados no ambiente observado (`EV-01`: `apiGateway/routes/projects.js:17-20`, `projects/routes/projects.js:79-83`, `projects/utils/httpsAgent.js:7-11`, baseline `0523102`; expiração registada em `AGENTS.md:119-120`, revisão `0f6dbc5`).],
  ),
) <tab-preparacao-ambiente>

*Como é orquestrado o processamento em lote de imagens e de vídeos:*

Quando o utilizador carrega em _Apply_, o navegador pede ao serviço `projects` que processe o projeto inteiro. O `projects` regista os trabalhos do lote antes de os despachar. Para cada imagem, envia uma mensagem por ferramenta e aguarda a resposta em `project_queue` antes de lançar a etapa seguinte. Para cada vídeo, envia o pipeline completo numa única mensagem em `video_queue`. O `video_tool` aplica os efeitos de fotograma contíguos numa passagem de descodificação e codificação. Na baseline, o worker envia o progresso de vídeo diretamente para `ws_queue`. Após o refactoring, o `projects` recebe os eventos em `project_queue`, valida-os, persiste os aceites e encaminha-os por `ws_queue` para o navegador. O `projects` grava os resultados no fim do processamento. A função `send_rabbit_msg` abre uma ligação por publicação e agenda o seu fecho após 500 ms (`EV-02`: `projects/utils/rabbit_mq.js:11-30`).




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
    [`doc-sol-arquitetural.pdf`], [Fase 2, 2025/2026, janeiro de 2026], [Referência da edição anterior. A análise da solução de base deste trabalho assenta no código da revisão `0523102` e nas fontes indicadas nesta secção.],
    [Slides das aulas teóricas e suporte], [Novembro de 2026], [Taxonomia de estilos arquiteturais (Camadas, Microsserviços, Event-Driven, Pipes & Filters) e táticas de desenho de software (Bass et al.).],
    [Documento de apoio de padrões arquiteturais (`docs/exercicios/RAS_support_doc_architectural_patterns_PT.html`)], [Material de apoio ao Exercício 6 (2026/2027)], [Descrição dos padrões considerados e do seu nível de análise (secções 1–7); fundamenta o padrão global, o padrão do vídeo e as alternativas `ALT-1` a `ALT-3` do capítulo 4.],
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

A arquitetura global do PictuRAS segue uma arquitetura de *microsserviços orientados a eventos* (*Event-Driven Microservices*), com uma camada perimetral de acesso e despacho (Nginx, API Gateway REST e WebSocket Gateway), comunicação assíncrona por filas de mensagens mediada por RabbitMQ e persistência desacoplada (MongoDB, SeaweedFS S3 e volume `image_data`). Na @fig-arquitetura-global, o caminho do processamento de vídeo está destacado a laranja. O percurso de progresso representado nessa figura corresponde à versão refatorada. A sequência da secção 2.4 mostra o percurso na baseline.

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

A sequência descreve a baseline `0523102`. Nessa revisão, o _worker_ publicava o progresso diretamente em `ws_queue` (`Tools/video/video.py:112-124`). A revisão `3cb1b74` publica eventos tipados em `project_queue`. O `projects` valida o token, persiste as atualizações aceites e encaminha-as por `ws_queue` para a interface (`EV-06`, revisão `3cb1b74`: mensagem em `Tools/video/progress.py:4-16` e `Tools/video/video.py:121-125`, validação e publicação em `projects/utils/videoProgress.js:3-75`, `projects/controllers/project.js:96-123`, `projects/routes/projects.js:228-238`, `projects/utils/project_msg.js:124-136` e `wsGateway/index.js:65-75`).

#paisagem[
#tab([Passos do pedido completo de vídeo],
  tabela(
    colunas: (3cm, 3.8cm, 1fr, 9.5cm),
    tamanho: 8.5pt,
    [Passo], [Origem $->$ Destino], [Mensagem / _endpoint_ / fila], [Evidência],
    [Carregamento do vídeo], [Browser $->$ Gateway $->$ `projects` $->$ `imageStorageService` $->$ S3], [`POST /api-gateway/projects/:user/:project/video` (multipart/form-data)], [`EV-03`, baseline `0523102`: upload e limites — `apiGateway/routes/projects.js:458-485`, `projects/routes/projects.js:1275-1317, 1390-1394`, `projects/utils/video.js:10-13, 84-143`; registo e despacho do lote — `projects/utils/processBatch.js:1-12`, `projects/routes/projects.js:1521-1671`.],
    [Definição do _pipeline_], [Browser $->$ Gateway $->$ `projects`], [`POST …/tool` (adicionar) e `POST …/reorder` (reordenar)], [`EV-03`: `apiGateway/routes/projects.js:506-566`; `projects/routes/projects.js:1397-1518`.],
    [Submissão (_Apply_)], [Browser $->$ Gateway $->$ `projects` $->$ RabbitMQ], [`POST /api-gateway/projects/:user/:project/process` $->$ publicação na fila `video_queue`], [`EV-04`, baseline `0523102`: `Tools/video/video.py:54, 76-92, 150-170, 172-174` (`prefetch_count=1`, resposta terminal em `project_queue`, processamento síncrono e ack manual após o resultado). `EV-05`, baseline `0523102`: `Tools/video/subtitles.py:15-21, 60-63` (execução síncrona do Faster-Whisper em CPU/`int8` para deteção de idioma e transcrição, bloqueando o consumidor durante todo o processamento). `EV-03`: `projects/utils/processBatch.js:1-12`, `projects/routes/projects.js:1521-1671`.],
    [Progresso (baseline)], [`video_tool` $->$ `ws_queue` $->$ `wsGateway` $->$ UI], [Notificações `video-progress` com percentagem por vídeo.], [`Tools/video/video.py:112-124`, baseline `0523102`. Para o fluxo refatorado, ver `EV-06` e a rota de estado `EV-07` na revisão `3cb1b74` (`projects/routes/projects.js:890-905`, `apiGateway/routes/projects.js:221-235`).],
    [Consolidação de resultados], [`video_tool` $->$ `project_queue` $->$ `projects` $->$ `ws_queue` $->$ `wsGateway` $->$ UI], [O _worker_ publica a resposta terminal e confirma a entrega original. O `projects` grava os resultados e notifica a interface.], [`EV-04`, baseline `0523102`: `Tools/video/video.py:76-92, 150-170`. Na revisão `3cb1b74`, o fecho passou a ser condicional (`EV-06`: `projects/routes/projects.js:437-489, 507-511`, `projects/controllers/project.js:128-160`). A regressão com barreira reproduziu a perda de resultados sob fecho concorrente (`H-01`). Após a correção, P-02 confirmou dois resultados distintos e descarregáveis (`docs/sessoes/2026-11-22-p02.md`).],
  ),
) <tab-passos-pedido>
]


== Onde e porquê o sistema bifurca entre imagem e vídeo

Embora a interface procure oferecer uma experiência unificada, o processamento de vídeo tem requisitos temporais e operacionais distintos dos das imagens. A implementação separa alguns percursos de validação, despacho e execução, resumidos na @tab-bifurcacao-media.

#tab([Pontos de bifurcação entre o caminho de imagens e o caminho de vídeo],
  tabela(
    colunas: (2.4cm, 3.2cm, 3.2cm, 1fr),
    tamanho: 8.5pt,
    [Ponto de bifurcação], [Caminho de imagens], [Caminho de vídeo], [Fundamentação arquitetural (facto / hipótese)],
    [Validação e Upload], [`POST …/img` rejeita ficheiros identificados como vídeo.], [`POST …/video` valida extensão/MIME e usa ffprobe para obter metadados; codec, duração, tamanho e resolução estão sujeitos a limites por perfil.], [Facto (`EV-03`): o vídeo exige verificação de contentor, _codec_, duração e limites por perfil, ausente no carregamento de imagem; por isso a rota tem validação própria.],
    [Despacho no Orquestrador], [Despacho passo a passo: uma mensagem por cada par (imagem, ferramenta) enviada para `<tool>_queue`.], [Despacho em bloco: uma mensagem por vídeo com o pipeline completo em `video_queue`.], [Facto (`EV-03`): o orquestrador despacha uma mensagem por vídeo com o _pipeline_ completo, para evitar descodificações e recodificações repetidas por ferramenta. `EV-04`, baseline `0523102`: `Tools/video/video_processor.py:190-218` aplica os efeitos de fotograma no mesmo ciclo de descodificação e codificação.],
    [Execução nos Trabalhadores], [Microsserviços PIL/IA autónomos e especializados.], [Serviço `video_tool`, com uma réplica por omissão no Compose.], [Facto (`EV-04`, `EV-08`: `docker-compose.yaml:255-273` e `Tools/video/video_processor.py:190-218, 316-363`, baseline `0523102`): Os efeitos de fotograma contíguos partilham uma passagem de descodificação e codificação.],
    [Confirmação AMQP (_Ack_)], [Confirmação automática imediata na receção (`auto_ack=True`).], [Confirmação manual explícita depois do processamento da mensagem.], [Facto (`EV-04`, `EV-09`: `Tools/utils/rabbit_mq.py:37-41`, baseline `0523102` — trabalhadores de imagem usam `auto_ack=True`): o auto-ack pode perder a tarefa se o _worker_ falhar durante o processamento.],
    [Interface de Utilizador], [Ferramentas de imagem e exportação PDF disponíveis para projetos de imagem.], [Em projetos com vídeo, a aplicação oculta as ferramentas exclusivas de imagem e não oferece exportação PDF; expõe as operações de vídeo (`trim`, `speed`, `subtitles`, `extract_frames`).], [Facto (`EV-10`, baseline `0523102`: `frontend/components/toolbar/toolbar.tsx:51-98` e `frontend/app/dashboard/[pid]/page.tsx:89-93, 841-850, 895-912` — ferramentas disponíveis por tipo de projeto, estado de progresso local, PDF oculto e overlay bloqueante).],
  ),
) <tab-bifurcacao-media>
