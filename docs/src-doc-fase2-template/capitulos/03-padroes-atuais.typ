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

#tabela-campos(
  [Nome(s) do padrão / estilo], [Arquitetura de microsserviços orientados a eventos.],
  [Descrição], [Nas estruturas estáticas, os serviços de negócio (`projects`, `users`, `subscriptions`, `imageStorageService`) e as ferramentas estão decompostos em módulos autónomos com baixo acoplamento. Nas estruturas dinâmicas, Nginx, gateway REST e Socket.IO medeiam o acesso do browser, enquanto o RabbitMQ desacopla o despacho da execução.],
)


#tab([Decisões globais que condicionam o vídeo],
  tabela(
    colunas: (3.8cm, 3.4cm, 1fr),
    tamanho: 8.5pt,
    [Decisão global], [Evidência], [Efeito no vídeo],
    [Filas e serviços por ferramenta], [EV-03, EV-04 e EV-08 (`docker-compose.yaml:255-273`, `rabbitMQ/definitions.json`)], [O _broker_ desacopla produtores e consumidores, permitindo escalar ou substituir trabalhadores sem alterar o contrato de entrada.],
    [Orquestração por tipo de media], [EV-03, `projects/utils/processBatch.js`], [As imagens seguem um encadeamento etapa a etapa; o vídeo é despachado com o _pipeline_ completo numa única mensagem para `video_queue`.],
    [Volume partilhado e S3], [`docker-compose.yaml:151, 271-273, 565`, baseline `0523102` --- volume `image_data` montado em todos os trabalhadores, a par do armazenamento S3], [Evita transportar ficheiros pesados nas mensagens AMQP, mas acopla os _workers_ ao sistema de ficheiros local `image_data`.],
  ),
) <tab-decisoes-globais>

#tab([Benefícios e desafios do padrão global],
  tabela(
    colunas: (2cm, 1fr, 4.2cm, 2.4cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [A separação de responsabilidades e o baixo acoplamento via filas permitem evoluir e escalar módulos de forma independente.], [Manutenibilidade, modularidade], [EV-03],
    [Benefício], [O processamento corre em segundo plano e o _frontend_ mantém-se responsivo durante lotes longos.], [Eficiência de desempenho, comportamento temporal], [EV-03],
    [Desafio], [A coordenação distribuída entre RabbitMQ, MongoDB e S3 expõe janelas de corrida no fecho concorrente de lotes e falhas parciais.], [Fiabilidade, recuperabilidade], [EV-06 e H-01],
    [Desafio], [O volume partilhado `image_data` pode tornar-se um gargalo de I/O ou um ponto único de falha sob maior concorrência.], [Eficiência de desempenho, utilização de recursos], [H-02],
  ),
) <tab-beneficios-globais>


== Padrão do processamento de vídeo

#orientacao[
  Identifiquem o padrão que organiza o processamento de vídeo (que pode coincidir com o global ou ser diferente) e
  contrastem-no com o caminho de imagens. Se o padrão do vídeo for diferente do global, expliquem porquê e que custos
  isso traz. Indiquem benefícios e desafios, com o mesmo critério da secção anterior.
]

#tabela-campos(
  [Nome do padrão], [Pipeline _batch-sequential_ / _pipe-and-filter_ interno encapsulado num único trabalhador assíncrono (`video_tool`).],
  [Descrição], [Um consumidor retira uma mensagem da fila `video_queue` (`prefetch_count=1`) e executa todo o _pipeline_ localmente. Efeitos contíguos de fotograma partilham a mesma passagem de descodificação e codificação em `Tools/video/effects.py`.],
  [Contraste com o caminho de imagens], [As ferramentas de imagem materializam um _pipe-and-filter_ distribuído: consomem filas próprias (`<tool>_queue`) e o orquestrador `projects` encadeia as etapas via `project_queue` (EV-03). O vídeo concentra todas as etapas num único serviço para evitar múltiplas recodificações e transferências em disco.],
)

O desvio em relação ao padrão global é deliberado. Repetir a decomposição por ferramenta multiplicaria o custo de CPU e de I/O: cada etapa reabriria, descodificaria e recodificaria o ficheiro de vídeo, em vez de pagar uma única passagem partilhada entre efeitos contíguos (EV-04, `Tools/video/effects.py`). O custo desta escolha é a perda de isolamento que o padrão global dá por garantida: enquanto um vídeo ocupa o único consumidor (`prefetch_count=1`), nenhum outro trabalho de vídeo avança. Uma falha numa dependência interna do serviço único afeta todos os efeitos e evoluir um efeito obriga a alterar o mesmo serviço. Os benefícios e desafios resumem-se na @tab-beneficios-video.

#tab([Benefícios e desafios do padrão do vídeo],
  tabela(
    colunas: (2cm, 1fr, 4.2cm, 2.4cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [Reduz a sobrecarga computacional e de I/O ao reutilizar a descodificação e codificação entre efeitos contíguos.], [Eficiência de desempenho, utilização de recursos], [EV-04 e `Tools/video/effects.py`],
    [Desafio], [A legendagem síncrona em CPU ocupa o único consumidor disponível e gera elevado tempo bloqueado (*blocked time*) para trabalhos curtos na fila.], [Eficiência de desempenho, capacidade], [EV-04 e EV-05; espera média de B = 61,727 s na baseline oficial (`evaluation/evidence/official-baseline-performance-2026-11-17/`)],
    [Desafio], [Baixa modularidade: uma falha numa dependência interna afeta o _worker_ inteiro, e evoluir um efeito obriga a alterar o serviço único.], [Fiabilidade, tolerância a falhas], [EV-04 e EV-05],
  ),
) <tab-beneficios-video>

== Relação entre o padrão global e o padrão do vídeo

#orientacao[
  Esta secção responde a: em que pontos o vídeo *segue* o padrão global, em que pontos se *afasta* dele e com que
  consequências? Cada linha da tabela é um aspeto concreto (e.g., comunicação entre serviços, gestão de estado,
  tratamento de falhas, armazenamento). É aqui que costumam surgir as fragilidades que alimentam os cenários de
  qualidade do capítulo 5, por isso escrevam as consequências com cuidado e com evidência.

  Terminem com um parágrafo de síntese: o que o vídeo herda do padrão global, que restrições este lhe impõe e que
  fragilidades resultam do desvio.
]

#tab([Relação entre o padrão global e o padrão do vídeo],
  tabela(
    colunas: (2.2cm, 2.9cm, 2.9cm, 1.8cm, 2.6cm, 2.1cm),
    tamanho: 8pt,
    [Aspeto], [O que o padrão global prescreve], [O que o vídeo faz], [Segue / afasta-se], [Consequência], [Evidência],
    [Comunicação assíncrona], [Despacho assíncrono via RabbitMQ], [Consumo assíncrono de `video_queue`], [Segue], [Mantém o desacoplamento temporal entre cliente e execução.], [EV-03 e EV-04],
    [Granularidade de despacho], [Uma mensagem por passo do _pipeline_ (par imagem, ferramenta)], [Uma única mensagem por vídeo com o _pipeline_ completo em `video_queue`], [Afasta-se], [O orquestrador deixa de ver os passos intermédios e cada vídeo ocupa integralmente um consumidor, alimentando o bloqueio de cabeça de fila (QS-01).], [EV-03 e EV-04],
    [Decomposição], [Um serviço autónomo por ferramenta (estilo distribuído)], [Pipeline completo num único worker (`video_tool`)], [Afasta-se], [Reduz transferências intermédias, mas concentra a carga num consumidor único.], [EV-03, EV-04 e EV-08],
    [Tratamento de falhas], [Consumo assíncrono com confirmação da entrega ao _broker_], [Confirmação manual (`ack`) após a resposta terminal; as ferramentas de imagem usam `auto_ack=True`], [Segue (as ferramentas de imagem é que se afastam)], [Evita perder tarefas por queda do _worker_, mas retém o consumidor até concluir o processamento.], [EV-04 e EV-09],
    [Estado na UI], [Progresso por eventos Socket.IO], [Overlay bloqueante e estado volátil na baseline], [Segue (com fragilidade)], [Qualquer navegação ou recarregamento destrói o acompanhamento visível; fragilidade da baseline, tratada no cenário QS-02.], [EV-06 e EV-10],
  ),
) <tab-relacao-padrao>

Em síntese, o processamento de vídeo herda a comunicação assíncrona por filas e a infraestrutura de armazenamento do padrão global, ficando sujeito à orquestração centralizada em `projects` e à partilha do volume `image_data`. Ao afastar-se da decomposição e da granularidade de despacho do padrão global para evitar recodificações dispendiosas, concentra toda a carga num único consumidor com `prefetch_count=1`, tornando o tempo de espera dos restantes projetos diretamente dependente da duração do trabalho ativo (bloqueio de cabeça de fila). Adicionalmente, a dependência de estado volátil na interface agrava o impacto dessa latência sobre a operabilidade. Estas fragilidades estão formalizadas nos cenários de qualidade QS-01 (bloqueio de cabeça de fila) e QS-02 (estado volátil na UI) do capítulo 5.
