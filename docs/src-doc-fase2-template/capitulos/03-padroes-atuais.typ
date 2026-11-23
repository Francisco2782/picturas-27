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
  [Nome(s) do padrão / estilo], [Microsserviços orientados a eventos.],
  [Descrição], [Serviços de negócio e ferramentas com execução assíncrona por RabbitMQ. Nginx, gateway REST e Socket.IO ligam o browser aos serviços.],
)

#tab([Decisões globais que condicionam o vídeo],
  tabela(
    colunas: (4.5cm, 2.6cm, 1fr),
    [Decisão global], [Evidência], [Efeito no vídeo],
    [Filas e serviços por ferramenta], [EV-02, `docker-compose.yaml` e `rabbitMQ/definitions.json`], [O broker desacopla o despacho da execução.],
    [Orquestração por tipo de media], [EV-04, `projects/utils/processBatch.js`], [Imagens avançam por efeito. O vídeo é despachado com o pipeline completo.],
  ),
)

#tab([Benefícios e desafios do padrão global],
  tabela(
    colunas: (2cm, 1fr, 4.2cm, 2.4cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [Escala independente dos módulos.], [Manutenibilidade, modularidade], [EV-04],
    [Desafio], [Coordenação de resultados entre RabbitMQ, MongoDB e S3.], [Fiabilidade, recuperabilidade], [EV-06 e auditoria F1],
  ),
)

== Padrão do processamento de vídeo

#orientacao[
  Identifiquem o padrão que organiza o processamento de vídeo (que pode coincidir com o global ou ser diferente) e
  contrastem-no com o caminho de imagens. Se o padrão do vídeo for diferente do global, expliquem porquê e que custos
  isso traz. Indiquem benefícios e desafios, com o mesmo critério da secção anterior.
]

#tabela-campos(
  [Nome do padrão], [Pipeline de vídeo dentro de um worker assíncrono.],
  [Descrição], [Um consumidor executa o pipeline por vídeo. Efeitos contíguos de fotograma partilham descodificação e codificação em `Tools/video/effects.py`.],
  [Contraste com o caminho de imagens], [As ferramentas de imagem consomem filas próprias e o orquestrador encadeia as etapas (EV-04).],
)

#tab([Benefícios e desafios do padrão do vídeo],
  tabela(
    colunas: (2cm, 1fr, 4.2cm, 2.4cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [Reutiliza a passagem de descodificação e codificação.], [Eficiência de desempenho, utilização de recursos], [EV-01 e `Tools/video/effects.py`],
    [Desafio], [A legendagem ocupa o único consumidor e atrasa trabalhos curtos.], [Eficiência de desempenho, capacidade], [EV-01 e EV-03, `Tools/video/subtitles.py`, e baseline oficial],
  ),
)

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

#tab([Relação entre o padrão global e o padrão do vídeo],
  tabela(
    colunas: (2.4cm, 3cm, 3cm, 1.9cm, 2.6cm, 1.8cm),
    tamanho: 8pt,
    [Aspeto], [O que o padrão global prescreve], [O que o vídeo faz], [Segue / afasta-se], [Consequência], [Evidência],
    [Mensageria], [Despacho assíncrono], [Consumo de `video_queue`], [Segue], [Mantém o desacoplamento entre cliente e execução.], [EV-01 e EV-04],
    [Decomposição], [Um serviço por ferramenta de imagem], [Pipeline completo por worker de vídeo], [Afasta-se], [Reduz transições intermédias e concentra a carga.], [EV-01 e EV-04],
  ),
)

O vídeo herda a mensageria e o armazenamento do sistema. O pipeline local evita transferências intermédias. Com um consumidor e `prefetch_count=1`, a duração do trabalho ativo afeta a espera dos restantes.
