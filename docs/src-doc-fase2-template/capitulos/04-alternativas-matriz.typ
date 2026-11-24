#import "../template.typ": *

= Alternativas e Matriz de Comparação

#orientacao[
  *Origem:* Exercício 6, Bloco 1, secção 3 do _template_.

  *Objetivo do capítulo:* comparar o padrão atual com alternativas relevantes *para o processamento de vídeo*, de forma
  fundamentada, e concluir se o padrão atual é adequado. Entre duas e três alternativas. O padrão global é o contexto da
  comparação: indiquem sempre se cada alternativa o *mantém* ou o *altera*.

  *Restrição da fase:* é de _refactoring_. As alternativas têm de preservar o comportamento funcional; por isso, o
  custo e o risco de migração têm de ser analisados para cada uma. Consultem os slides da aula 11 e o documento de apoio
  de padrões arquiteturais; se for relevante, incluam uma alternativa ao próprio padrão global como termo de comparação.
]

== Alternativas consideradas

Para mitigar as limitações de capacidade, concorrência e comportamento temporal identificadas na solução de base, foram formuladas três alternativas arquiteturais no domínio do processamento de vídeo, confrontadas com o padrão global existente na @tab-alternativas-resumo.

#tab([Alternativas consideradas],
  tabela(
    colunas: (1.6cm, 3.4cm, 1fr, 3cm, 2.4cm),
    tamanho: 8.5pt,
    [ID], [Nome / padrão], [Descrição breve], [Mantém ou altera o padrão global?], [Fonte],
    [ALT-1], [Consumidores Concorrentes (*Competing Consumers*)], [Escala horizontal de réplicas do trabalhador `video_tool` partilhando a mesma fila `video_queue` com prefetch unitário.], [Mantém integralmente], [Padrão Competing Consumers (doc. apoio, secção 7)],
    [ALT-2], [Microsserviços Distribuídos de Vídeo (*Pipes & Filters*)], [Decomposição de cada filtro de vídeo num microsserviço isolado com fila própria, encadeados passo a passo.], [Altera o padrão do vídeo (converge com imagens)], [Padrão Pipes and Filters (doc. apoio, secções 3 e 6)],
    [ALT-3], [Filas Separadas por Tipo de Carga (*Workload Queues*)], [Segregação de tráfego em duas filas AMQP: uma para filtros rápidos de cor e corte, e outra para tarefas CPU-bound (legendas).], [Altera a topologia de despacho], [Padrão Priority/Workload Queues (slides aula 11)],
  ),
) <tab-alternativas-resumo>

== Análise de cada alternativa

#orientacao[
  Copiem o bloco abaixo para cada alternativa. Para cada uma, descrevam a coerência com o padrão global, o efeito nos
  atributos de qualidade, as vantagens, as desvantagens ou riscos, e o custo e risco de migração. Evitem listas
  genéricas: cada ponto deve referir algo concreto da solução do PictuRAS (e citar evidência `EV-nn` ou hipótese `H-nn`).
]

*ALT-1 — Consumidores Concorrentes com Réplicas do Worker de Vídeo*

A alternativa ALT-1 mantém a estrutura interna do trabalhador monolítico de vídeo, mas escala horizontalmente o número de instâncias ativas do serviço `video_tool` sobre a fila durável existente `video_queue`.

#tabela-campos(
  [Coerência com o padrão global], [Totalmente coerente. Reutiliza o barramento RabbitMQ existente, a fila durável `video_queue` e o contrato de mensagens de despacho em lote sem necessitar de qualquer alteração na camada perimetral ou nos serviços clientes.],
  [Efeito nos atributos de qualidade], [Permite o processamento em paralelo de pedidos de múltiplos utilizadores ou projetos. Reduz drasticamente o tempo de espera de trabalhos curtos que anteriormente ficavam retidos atrás de legendagens lentas. Em contrapartida, aumenta o consumo agregado de memória RAM no host.],
  [Vantagens potenciais], [Preserva o pipeline em passagem única (*single-pass*) com uma só codificação e descodificação em memória; viabiliza o avanço concorrente do Projeto B durante o processamento do Projeto A sem alterar contratos de software.],
  [Desvantagens ou riscos], [Risco crítico de condições de corrida no orquestrador `projects` quando múltiplos vídeos de um lote terminam concorrentemente (identificado na auditoria e resolvido na prova P-02); duplicação de modelos Faster-Whisper em RAM por réplica.],
  [Custo e risco de migração], [Custo e risco muito reduzidos. Enquadra-se estritamente como _refactoring_ puro (Classe A), implementável via Docker Compose com ajustes cirúrgicos de sincronização de escrita no orquestrador.],
)

*ALT-2 — Decomposição em Microsserviços Distribuídos de Vídeo*

A alternativa ALT-2 procura alinhar a arquitetura de vídeo com a solução de imagens, criando contentores e filas dedicadas para cada operação de vídeo (`video_crop`, `video_brightness`, `video_subtitles`).

#tabela-campos(
  [Coerência com o padrão global], [Alinha-se com o modelo de microsserviços especializados das imagens, aplicando um padrão _Pipes and Filters_ distribuído.],
  [Efeito nos atributos de qualidade], [Aumenta a modularidade e a isolabilidade de falhas entre ferramentas. No entanto, degrada severamente o comportamento temporal e a eficiência de recursos devido à necessidade de descodificar e recodificar fluxos H.264/AAC entre cada filtro intermédio, além de gerar tráfego massivo no sistema de ficheiros.],
  [Vantagens potenciais], [Isolamento total de processos (uma falha na legendagem não afeta o brilho) e escalabilidade granular por ferramenta com base na procura específica.],
  [Desvantagens ou riscos], [Degradação cumulativa de qualidade por recompressão sucessiva com perdas (*lossy re-encoding*); explosão do tempo total de processamento devido ao I/O em disco; orquestração complexa com alto risco de perda de sincronismo entre áudio e vídeo.],
  [Custo e risco de migração], [Custo e risco de migração proibitivos. Exigiria a reescrita total da orquestração em `projects`, o desenvolvimento e empacotamento de múltiplos novos contentores e a redefinição de esquemas de mensagens, violando o princípio de _refactoring_ da Fase 2.],
)

*ALT-3 — Filas Separadas por Tipo de Carga (Tarefas Leves vs. Pesadas)*

A alternativa ALT-3 mantém o pipeline agrupado por vídeo, mas cria duas filas distintas no RabbitMQ: `video_light_queue` para filtros simples de fotogramas e `video_heavy_queue` para transcrição fonética com Faster-Whisper ou extração massiva de fotogramas.

#tabela-campos(
  [Coerência com o padrão global], [Mantém a assincronia e o intercâmbio de dados existente, mas afasta-se da simplicidade do contrato de despacho do orquestrador ao introduzir regras de classificação prévia de pedidos.],
  [Efeito nos atributos de qualidade], [Garante isolamento de desempenho e previsibilidade para tarefas rápidas, impedindo que fiquem bloqueadas por tarefas de IA. Contudo, pode originar subutilização de recursos se uma das filas estiver ociosa enquanto a outra acumula carga pendente.],
  [Vantagens potenciais], [Reserva garantida de capacidade para tarefas interativas e dimensionamento assimétrico de recursos de CPU consoante o perfil de computação.],
  [Desvantagens ou riscos], [Complexidade no orquestrador para classificar pipelines mistos (um lote que combine brilho e legendas exige divisão ou classificação conservadora); risco de desperdício de capacidade de trabalhadores especializados ociosos.],
  [Custo e risco de migração], [Custo e risco médios. Exigiria refatorar a lógica de encaminhamento em `projects/utils/processBatch.js`, reconfigurar o ficheiro de definições do RabbitMQ e gerir múltiplos pools de consumidores.],
)

#paisagem[
== Matriz de comparação de padrões

#orientacao[
  Atribuam um nível a cada atributo para o padrão global (referência), para o padrão atual do vídeo e para cada
  alternativa. A escala é à vossa escolha (e.g., Alto / Médio / Baixo) e deve ser a mesma em toda a matriz.

  *Justifiquem cada célula* com evidência da solução (`EV-nn` ou `H-nn`) numa frase curta, logo na própria célula: as
  avaliações sem fundamento não são valorizadas. A matriz inclui o padrão global como referência para se ver o que
  cada alternativa ganha ou perde em relação a ele. Os atributos e subcaracterísticas seguem a ISO/IEC 25010; podem
  acrescentar linhas para outros atributos relevantes.
]

Na @tab-matriz-comparacao, confronta-se o padrão global com o padrão atual do vídeo e as três alternativas propostas, avaliando o impacto nos atributos de qualidade da norma ISO/IEC 25010 fundamentado em evidências concretas.

#tab([Matriz de comparação de padrões],
  tabela(
    colunas: (5.2cm, 3.8cm, 3.8cm, 4cm, 4cm, 3.8cm),
    tamanho: 8pt,
    [Atributo de qualidade (ISO/IEC 25010)], [Padrão global atual (referência)], [Padrão atual do vídeo], [ALT-1 (Consumidores Concorrentes)], [ALT-2 (Vídeo Distribuído)], [ALT-3 (Filas Separadas)],
    [Relação com padrão global], [—], [Afasta-se (Pipeline Monolith agrupado)], [Mantém o padrão global e a fila única], [Aproxima o vídeo do padrão distribuído de imagens], [Mantém a assincronia e altera o encaminhamento],
    [Desempenho: comportamento temporal], [Médio — depende do encadeamento passo a passo (`EV-01`)], [Baixo — bloqueio total por legendas longas (`EV-02`, `EV-03`)], [Alto — lote B arrancou em 0,113 s durante A (`H-03`: cenário A/B automatizado; confirmada — 0,113 s, `M-02`)], [Muito baixo — descodificações e codificações repetidas], [Alto para tarefas leves se houver worker livre],
    [Desempenho: capacidade / elasticidade], [Alto — escalabilidade independente por ferramenta (`EV-07`)], [Muito baixo — instância única com prefetch unitário (`EV-06`)], [Alto na carga testada — 2 réplicas concorrentes validadas (`P-01`)], [Médio — escala por etapa mas satura CPU e I/O de disco], [Médio — escala por fila mas com risco de capacidade ociosa],
    [Fiabilidade: tolerância a falhas / recuperabilidade], [Média — ferramentas de imagem usam `auto_ack=True` (`EV-07`)], [Alta — ack manual no final e ficheiro `.part` (`EV-02`)], [Alta — preserva ack manual e trata fecho simultâneo (`P-02`)], [Baixa — múltiplos pontos de falha intermédios em cadeia], [Alta — preserva ack manual se mantiver contrato de confirmação],
    [Manutenibilidade: modularidade / modificabilidade], [Alta — contentores pequenos e autónomos (`EV-01`)], [Média — monólito concentra múltiplos filtros (`EV-02`)], [Média — mantém a base de código do worker de vídeo], [Alta — isola ferramentas em microsserviços próprios], [Média — adiciona regras de classificação de tarefas no orquestrador],
    [Segurança: controlo de acessos], [Controlo perimetral via JWT; dívida de TLS interno (`EV-09`: `apiGateway/routes/projects.js:18`, TLS interno — certificados autoassinados expirados com `rejectUnauthorized: false`)], [Isolamento em contentor Docker sob a rede interna], [Mantém exatamente os mesmos contratos e fronteiras], [Exige controlo de acessos e credenciais em novos serviços], [Requer controlo e permissões sobre as novas filas AMQP],
    [Usabilidade: operabilidade], [Desacoplado no backend; interface volátil na base (`EV-08`)], [Modal sobreposto bloqueia ecrã e perde estado (`EV-08`)], [Redução da espera comprovada; operabilidade tratada via UI (`H-04`: ensaio protocolado no Chromium com navegação e refresh durante a execução; confirmada — 12/12 ações e 3/3 recuperações)], [Depende do frontend; maior lentidão global afeta a experiência], [Reduz espera de filtros simples; operabilidade requer UI desacoplada],
  ),
) <tab-matriz-comparacao>
]

== Adequação do padrão atual

A análise comparativa demonstra que o padrão global da solução (Microsserviços Orientados a Eventos) é conceptualmente adequado e robusto para as operações de gestão de projetos, controlo de acessos e coordenação de ficheiros do PictuRAS. No domínio específico do vídeo, o desvio para um *Pipeline Monolith* foi uma decisão técnica acertada para viabilizar a eficiência temporal e a integridade de codecs, eliminando a sobrecarga insustentável que a alternativa ALT-2 provocaria.

No entanto, a sua concretização na versão de base — associada a uma única instância de execução com receção estritamente serializada (`prefetch_count=1`) — revelou-se manifestamente inadequada para sustentar um serviço multi-utilizador concorrente, originando um bloqueio inaceitável face a tarefas pesadas de transcrição em CPU.

A alternativa *ALT-1 (Competing Consumers)* foi selecionada como a decisão de _refactoring_ prioritária. Ao instanciar duas réplicas concorrentes do trabalhador sobre a fila durável existente `video_queue`, ALT-1 preserva a integridade do pipeline em passagem única e os contratos de despacho do orquestrador, eliminando o bloqueio de pedidos e alcançando a meta de capacidade sem os riscos e custos desproporcionados de reestruturação associados às alternativas ALT-2 e ALT-3.
