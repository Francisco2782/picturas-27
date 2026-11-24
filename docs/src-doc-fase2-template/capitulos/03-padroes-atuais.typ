#import "../template.typ": *

= Padrões Arquiteturais Atuais

#orientacao[
  *Origem:* Exercício 6, Bloco 1, secções 2.1 a 2.3 do _template_.

  *Objetivo do capítulo:* identificar o estilo (ou a combinação de estilos) arquitetural que organiza o PictuRAS como um
  todo, o padrão que o processamento de vídeo segue, e como os dois se relacionam. O padrão global é o *ponto de
  partida*: define o contexto e as restrições a que qualquer alternativa terá de responder (capítulo 4).

  *Rigor:* factos citam uma evidência (`EV-nn`, ver a explicação na secção 2.4); o que não tem evidência é uma hipótese
  (`H-nn`). Nunca reutilizem um ID eliminado. Benefícios e desafios classificam-se segundo a ISO/IEC 25010
  (característica e, quando aplicável, subcaracterística).
]

== Padrão global da solução

#orientacao[
  Nomeiem o estilo ou os estilos (e.g., microserviços, orientado a eventos, filas de mensagens) e descrevam-no em poucas
  linhas, com as vossas palavras. Depois, indiquem as *decisões globais* que condicionam o vídeo (e.g., comunicação
  assíncrona por filas, armazenamento partilhado) e o efeito que têm. Fechem com os benefícios e desafios do padrão,
  cada um ligado a um atributo de qualidade.
]


No nível macro, a arquitetura da solução PictuRAS estrutura-se através de uma combinação coerente de padrões arquiteturais consolidados:
- *Microsserviços (Microservices Architecture)*: O domínio funcional é decomposto em serviços autónomos por área de negócio (`users`, `projects`, `subscriptions`, `imageStorageService`) e ferramentas de processamento especializadas (`Tools/*`). Cada microsserviço possui ciclo de vida e implantação independentes em contentores Docker, aplicando estritamente o padrão *Database per Service*, com persistência encapsulada em coleções isoladas de MongoDB e repositórios desacoplados.
- *API Gateway / Reverse Proxy* e *WebSocket Gateway (Perímetro)*: O perímetro de rede é unificado através do Nginx em conjunto com o serviço `apiGateway` (Express.js), atuando como porta de entrada única para o tráfego externo proveniente da aplicação web em Next.js (SPA). Centraliza a terminação de ligações seguras, o roteamento reverso de chamadas REST e a validação de autenticação e autorização através de tokens JWT (`EV-09`). Em paralelo, o *WebSocket Gateway* (`wsGateway`, assente em Socket.IO) atua como canal perimetral bidirecional persistente, especializado no envio reativo de eventos de estado e progresso para o navegador.
- *Arquitetura Orientada a Eventos (Event-Driven Architecture - EDA)* com *Message Broker*: O desacoplamento temporal e espacial entre o orquestrador e os trabalhadores de computação é assegurado pelo _broker_ RabbitMQ (utilizando um _exchange_ direto `picturas` e filas duráveis `<tool>_queue`, `video_queue`, `project_queue`, `ws_queue`). O cliente HTTP obtém resposta imediata de aceitação após a submissão do pedido (_Apply_), decorrendo todo o processamento computacionalmente pesado em segundo plano de forma não bloqueante.
- *Orquestrador Centralizado de Processos (Orchestrator / Process Manager)*: O microsserviço `projects` atua como orquestrador central do ciclo de vida dos pedidos em lote. Concentra a máquina de estados dos projetos, a verificação síncrona de autorizações e quotas de operações diárias junto de `users`, a coordenação das etapas de processamento e a consolidação final dos artefactos gerados.
- *Padrão Claim Check (com Armazenamento Partilhado e Object Storage)*: Para prevenir a sobrecarga e saturação de memória no _broker_ de mensagens com ficheiros multimédia pesados (vídeos de dezenas ou centenas de megabytes), as mensagens AMQP transportam exclusivamente referências, metadados e identificadores (`imgId`, caminhos). Os ficheiros binários em trânsito são acedidos diretamente através de um volume de sistema de ficheiros partilhado montado localmente (`image_data`), enquanto o arquivo durável e o fornecimento de artefactos finais ao utilizador são delegados ao _Object Storage_ compatível com S3 (SeaweedFS, intermediado por `imageStorageService`).
- *Service-Oriented Architecture (SOA) / RESTful SOA*: A integração síncrona interna entre o `apiGateway` e os serviços de negócio opera com base em contratos formais de interfaces RESTful sobre HTTP/JSON.
- *Padrão em Camadas (Layered Architecture)* a nível interno: Cada serviço Node.js/Express estrutura-se internamente em camadas hierárquicas bem definidas (`routes` $->$ `controllers` $->$ `models`), desacoplando o tratamento de protocolos de transporte, a lógica de negócio e o acesso aos dados.

#tabela-campos(
  [Nome(s) do padrão / estilo], [Microsserviços Orientados a Eventos com API Gateway, Orquestrador Centralizado, Claim Check e Pipes and Filters Distribuído.],
  [Descrição arquitetural], [A solução decompõe o domínio funcional em serviços autónomos por área de negócio (`users`, `projects`, `subscriptions`, `imageStorageService`) e ferramentas de processamento especializadas. O tráfego externo proveniente da aplicação web em Next.js é canalizado através do Nginx e centralizado pelo `apiGateway` (para operações REST autenticadas via JWT) e pelo `wsGateway` (para comunicação bidirecional com Socket.IO). A execução das operações de transformação é totalmente assíncrona e desacoplada, utilizando o _broker_ RabbitMQ para entrega de mensagens e persistência mista: bases de dados isoladas por serviço (MongoDB), _Object Storage_ para artefactos finais (SeaweedFS S3) e um volume de ficheiros partilhado montado localmente (`image_data`) para troca rápida de binários de imagem e vídeo sob o padrão _Claim Check_.],
)

As decisões de âmbito global exercem restrições diretas sobre o comportamento da extensão de vídeo, descritas na @tab-decisoes-globais.

#tab([Decisões globais que condicionam o vídeo],
  tabela(
    colunas: (4.5cm, 2.6cm, 1fr),
    [Decisão global], [Evidência], [Efeito no vídeo],
    [Orquestração centralizada baseada em estados (`projects`)], [`EV-01`, `projects/routes/projects.js`], [O orquestrador centraliza o ciclo de vida dos pedidos, gere quotas e dita as transições de estado, forçando o tratamento diferenciado do vídeo perante imagens.],
    [Padrão Claim Check via volume partilhado (`image_data`)], [`docker-compose.yaml:26-30`, `EV-06`], [Exige que os trabalhadores de vídeo executem no mesmo nó ou partilhem o sistema de ficheiros montado, condicionando a escalabilidade distribuída multi-máquina.],
    [Mensageria assíncrona desacoplada via RabbitMQ], [`EV-01`, `EV-02`, `rabbitMQ/definitions.json`], [O progresso, o cancelamento e as confirmações dependem estritamente da robustez operacional e da topologia de filas (`video_queue`, `project_queue`).],
  ),
) <tab-decisoes-globais>

Os benefícios e desafios associados ao padrão global da plataforma encontram-se sistematizados na @tab-beneficios-global, classificados segundo a norma ISO/IEC 25010.

#tab([Benefícios e desafios do padrão global],
  tabela(
    colunas: (2cm, 1fr, 4.4cm, 2.2cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [Desacoplamento e escalabilidade independente dos módulos de negócio e ferramentas.], [Manutenibilidade: modularidade e modificabilidade], [Facto (`EV-01`)],
    [Benefício], [Processamento assíncrono em segundo plano que liberta o cliente HTTP imediatamente após submissão.], [Eficiência de desempenho: comportamento temporal], [Facto (`EV-01`)],
    [Desafio], [Complexidade de transações distribuídas e consistência de dados entre MongoDB, S3 e RabbitMQ.], [Fiabilidade: recuperabilidade e integridade], [Facto (`EV-04`, `fase-2-auditoria.md`)],
    [Desafio], [Ponto único de falha e contenção de I/O decorrentes da partilha do volume montado `image_data`.], [Eficiência de desempenho: utilização de recursos], [Hipótese (`H-02`: monitorização de I/O de disco sob carga intensiva de múltiplos lotes; por confirmar, fora do âmbito)],
  ),
) <tab-beneficios-global>

== Padrão do processamento de vídeo

#orientacao[
  Identifiquem o padrão que organiza o processamento de vídeo (que pode coincidir com o global ou ser diferente) e
  contrastem-no com o caminho de imagens. Se o padrão do vídeo for diferente do global, expliquem porquê e que custos
  isso traz. Indiquem benefícios e desafios, com o mesmo critério da secção anterior.
]

Em contraste evidente com a decomposição granular aplicada às imagens estáticas — onde cada filtro PIL ou modelo de inteligência artificial funciona como um contentor individual e isolado num padrão *Pipes and Filters Distribuído* com fila dedicada —, o subsistema de processamento de vídeo afasta-se deliberadamente dessa abordagem e adota o padrão de *Pipeline Monolith sob Trabalhador Assíncrono com Passagem Única* (*Single-Pass Pipeline Worker*).

Em articulação com este desenho interno, e no que diz respeito aos padrões de concorrência e consumo de filas catalogados na literatura teórica (*Competing Consumers / Work Queue*), a solução de base configura o subsistema de vídeo como uma *Fila de Trabalho com Consumidor Único* (*Single Consumer Work Queue*). O contentor `video_tool` opera como consumidor isolado sobre a fila durável `video_queue`, configurado com receção unitária estrita (`prefetch_count=1`, `EV-02`) e executando uma única réplica por omissão (`EV-06`).

#tabela-campos(
  [Nome do padrão], [Pipeline Monolith sob Trabalhador Assíncrono (*Single-Pass Processing*) com Fila de Trabalho de Consumidor Único (*Single Consumer Work Queue*).],
  [Descrição], [Todas as capacidades de manipulação de vídeo — filtros de ajuste de cor (brilho, contraste, saturação), transformações temporais (`trim`, `speed`), legendagem automática por transcrição fonética (Faster-Whisper) e extração de fotogramas (`extract_frames`) — encontram-se agrupadas num único microsserviço monolítico (`video_tool`). O trabalhador consome mensagens da fila `video_queue`, descodifica o fluxo de vídeo com FFmpeg/OpenCV uma única vez, aplica a sequência contígua de transformações sobre os fotogramas em memória e codifica o resultado final num único passo gerador de ficheiro MP4 (H.264 + áudio AAC).],
  [Contraste com o caminho de imagens], [O processamento de imagens aplica um padrão _Pipes and Filters_ distribuído puro: cada filtro é um contentor independente com a sua própria fila e o orquestrador `projects` encadeia as etapas passo a passo. No vídeo, o pipeline completo é delegado e consolidado numa execução unificada dentro do mesmo processo trabalhador.],
)

=== Integração da legendagem automática e da extração de fotogramas

A inclusão de capacidades de maior complexidade algorítmica no subsistema de vídeo — especificamente a transcrição fonética com Faster-Whisper e a extração discreta de fotogramas — colocou desafios adicionais de integração ao padrão monolítico do trabalhador, sintetizados na @tab-legendagem-fotogramas.

#tab([Integração da legendagem e extração de fotogramas no padrão de vídeo],
  tabela(
    colunas: (3.2cm, 4.4cm, 1fr, 2.2cm),
    tamanho: 8.5pt,
    [Funcionalidade], [Integração no padrão do vídeo], [Impacto nos atributos de qualidade (ISO/IEC 25010)], [Evidência],
    [Legendagem automática (`subtitles`)], [Etapa síncrona interna em `video_tool`, executando o modelo Faster-Whisper em CPU com quantização `int8` e gravação de legendas com FFmpeg.], [Degradação severa do comportamento temporal e da capacidade: consome 100% de CPU durante dezenas de segundos, bloqueando toda a `video_queue` sob consumidor único.], [`EV-03`, `Tools/video/subtitles.py:15-21`],
    [Extração de fotogramas (`extract_frames`)], [Passo terminal obrigatório e único no pipeline, gerando uma coleção de imagens PNG/JPEG ou folha de contacto.], [Pressão acrescida sobre o volume partilhado `image_data` e necessidade de conversão de 1 resultado de vídeo em múltiplos registos `Result` no MongoDB.], [`EV-01`, `Tools/video/frame_extraction.py`, `AGENTS.md`],
  ),
) <tab-legendagem-fotogramas>

Os benefícios e desafios associados ao padrão do processamento de vídeo encontram-se sistematizados na @tab-beneficios-video, classificados segundo a norma ISO/IEC 25010.

#tab([Benefícios e desafios do padrão do vídeo],
  tabela(
    colunas: (2cm, 1fr, 4.4cm, 2.2cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição arquitetural], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [Eliminação de ciclos repetidos de descodificação e recodificação de vídeo em disco, poupando CPU e I/O.], [Eficiência de desempenho: utilização de recursos], [Facto (`EV-02`, `Tools/video/effects.py`)],
    [Benefício], [Preservação da fidelidade do áudio e mitigação da degradação cumulativa de codecs com perdas (_lossy codecs_).], [Adequação funcional: integridade], [Facto (`EV-02`, `Tools/video/video_processor.py`)],
    [Desafio], [Estrangulamento severo por bloqueio de cabeça de fila (*Head-of-Line Blocking*): uma legendagem demorada ocupa o único consumidor e atrasa todos os pedidos concorrentes.], [Eficiência de desempenho: capacidade], [Facto (`EV-02`, `EV-03`, `EV-06`, baseline oficial `b_wait_seconds = 61,727 s`)],
    [Desafio], [Monólito pesado com acoplamento interno: falhas em bibliotecas complexas (ex.: Faster-Whisper) podem comprometer todo o serviço de vídeo.], [Fiabilidade: tolerância a falhas], [Facto (`EV-02`, `EV-03`)],
  ),
) <tab-beneficios-video>

#pagebreak(weak: true)
== Relação entre o padrão global e o padrão do vídeo

#orientacao[
  Esta secção responde a: em que pontos o vídeo *segue* o padrão global, em que pontos se *afasta* dele e com que
  consequências? Cada linha da tabela é um aspeto concreto (e.g., comunicação entre serviços, gestão de estado,
  tratamento de falhas, armazenamento). É aqui que costumam surgir as fragilidades que alimentam os cenários de
  qualidade do capítulo 5, por isso escrevam as consequências com cuidado e com evidência.

  Terminem com um parágrafo de síntese: o que o vídeo herda do padrão global, que restrições este lhe impõe e que
  fragilidades resultam do desvio.
]

A comparação sistemática entre os princípios orientadores do padrão global da plataforma e as opções concretizadas no subsistema de processamento de vídeo encontra-se detalhada na @tab-relacao-padroes.

#tab([Relação entre o padrão global e o padrão do vídeo],
  tabela(
    colunas: (2.4cm, 3cm, 3cm, 1.8cm, 2.8cm, 1.8cm),
    tamanho: 8pt,
    [Aspeto], [O que o padrão global prescreve], [O que o vídeo faz], [Segue / afasta-se], [Consequência], [Evidência],
    [Decomposição Funcional], [Um microsserviço e uma fila dedicada por cada ferramenta de processamento.], [Todas as operações de vídeo agregadas no contentor monolítico `video_tool`.], [Afasta-se], [Minimiza sobrecargas de I/O e recodificação, mas concentra toda a carga num serviço monolítico pesado.], [`EV-01`, `EV-06`],
    [Estilo de Pipeline], [Pipes and Filters Distribuído puro com encadeamento passo a passo.], [Pipeline Monolith local com execução em memória numa única passagem.], [Afasta-se], [Otimiza o processamento contíguo, mas impede a escalabilidade independente por ferramenta.], [`EV-01`, `EV-02`],
    [Granularidade de Despacho], [Uma mensagem AMQP individual por cada etapa (imagem, ferramenta) do pipeline.], [Mensagem única contendo o array completo de operações do pipeline.], [Afasta-se], [O orquestrador perde visibilidade direta dos passos intermédios, passando a depender de eventos de progresso.], [`EV-01`, `projects/utils/processBatch.js`],
    [Consumo de Filas], [Múltiplos consumidores distribuídos em paralelo pelas diferentes ferramentas.], [Fila de trabalho com consumidor único (`prefetch_count=1`, réplica única na base).], [Afasta-se], [Bloqueio de cabeça de fila (*Head-of-Line Blocking*); tarefas longas imobilizam pedidos concorrentes.], [`EV-02`, `EV-06`],
    [Comunicação Assíncrona], [Mensageria assíncrona desacoplada através do _broker_ RabbitMQ.], [Consumo assíncrono através da fila durável `video_queue` e reporte na `project_queue`.], [Segue], [Preserva o desacoplamento temporal e estrutural entre o utilizador e a computação em lote.], [`EV-01`, `EV-02`, `rabbitMQ/definitions.json`],
    [Intercâmbio de Dados], [Padrão Claim Check: volume partilhado `image_data` e S3 para arquivo.], [Lê entradas e escreve saídas temporárias no volume `image_data` e final no S3.], [Segue], [Assegura plena interoperabilidade de dados com os serviços perimetrais e de arquivo.], [`EV-01`, `docker-compose.yaml:26-30`],
    [Confirmação AMQP], [Confirmação automática imediata na receção (`auto_ack=True`).], [Confirmação manual explícita (`basic_ack`) apenas no final com ficheiro atómico `.part`.], [Afasta-se], [Evita a perda de tarefas pesadas e não confirmadas em caso de paragem do contentor.], [`EV-02`, `EV-07`],
  ),
) <tab-relacao-padroes>

=== Suporte aos requisitos não funcionais e regras implícitas

A análise de adequação dos padrões em confronto perante os requisitos não funcionais herdados da Fase 1 (`doc-ext-requisitos-2627.pdf`) e as regras operacionais sem requisito explícito encontra-se detalhada na @tab-suporte-requisitos-regras.

#tab([Suporte aos requisitos não funcionais herdados e regras de negócio],
  tabela(
    colunas: (3.4cm, 2.2cm, 2.2cm, 1fr, 2cm),
    tamanho: 8pt,
    [Requisito / regra], [Padrão global suporta?], [Padrão do vídeo suporta?], [Fundamentação arquitetural], [Evidência],
    [`REQ-VID-EDIT-010` (Desempenho da edição de vídeo)], [Parcial], [Sim], [O _single-pass processing_ otimiza o tempo individual ao partilhar uma descodificação/codificação.], [`EV-02`, `Tools/video/video_processor.py`],
    [`REQ-VID-EDIT-011` (Capacidade concorrente)], [Sim], [Não (na base)], [A réplica única de `video_tool` com `prefetch_count=1` serializa todos os pedidos de utilizadores concorrentes.], [`EV-02`, `EV-06`, baseline oficial],
    [`REQ-VID-EDIT-002` (Sessão não bloqueante)], [Sim], [Não (na base)], [O backend é assíncrono, mas a interface web base bloqueava o ecrã com uma janela modal sobreposta.], [`EV-08`, `frontend/app/dashboard/[pid]/page.tsx`],
    [`REQ-VID-FAIL-004` (Não perder trabalho em falha)], [Parcial], [Sim], [O trabalhador de vídeo utiliza `basic_ack` manual no fim e gera ficheiro temporário `.part` atómico.], [`EV-02`, `Tools/video/video.py:170`],
    [`REQ-VID-STATUS-003` (Acompanhamento em tempo real)], [Sim], [Parcial], [Emite eventos de progresso via WebSocket, mas o estado perdia-se no recarregamento da página.], [`EV-04`, `EV-08`],
    [Regra: Extração de fotogramas é terminal e única], [N/A], [Sim], [Garantido por validação formal no orquestrador e respeitado na cadeia do trabalhador monolítico.], [`EV-01`, `AGENTS.md`],
    [Regra: `trim`/`speed` por vídeo, efeitos de cor para todos], [Parcial], [Sim], [O orquestrador discrimina parâmetros individuais (`params.imgId`) na composição da mensagem AMQP.], [`EV-01`, `AGENTS.md`],
  ),
) <tab-suporte-requisitos-regras>

*Síntese da relação entre padrões:*

O subsistema de vídeo herda do padrão global a infraestrutura de mensageria assíncrona (RabbitMQ), o modelo de segurança perimetral (JWT), o mecanismo de intercâmbio de dados por referência (_Claim Check_) e o canal de reporte de eventos em tempo real para o navegador (`wsGateway`). No entanto, o padrão global foi originalmente concebido a pensar em operações ultrarrápidas de imagem (frações de segundo com PIL), assentando na premissa de que a orquestração passo a passo pelo broker tinha custo negligenciável.

Para ficheiros de vídeo de centenas de megabytes, transitar dados entre múltiplos contentores implicaria penalizações catastróficas de I/O em disco e perda cumulativa de qualidade por recompressão sucessiva (*lossy codecs*). O desvio intencional para um *Pipeline Monolith sob Trabalhador Assíncrono* revelou-se tecnicamente indispensável para viabilizar a eficiência de desempenho e a integridade do sinal multimédia.

Contudo, a concretização desse padrão na solução de base — associada a uma *Fila de Trabalho com Consumidor Único* (`prefetch_count=1` e uma única réplica por omissão) — introduziu uma fragilidade estrutural grave de *capacidade e elasticidade*: a chegada de tarefas demoradas de inteligência artificial (Faster-Whisper em CPU) monopoliza o trabalhador e condena todos os pedidos concorrentes a uma espera inaceitável em fila durável. Esta disfunção arquitetural estabelece a motivação direta para as alternativas de _refactoring_ analisadas no Capítulo 4.
