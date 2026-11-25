#import "../template.typ": *

#paisagem[
= Trade-offs, Cenários de Qualidade e Prioridades

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 4 do _template_ (sem a justificação detalhada da matriz, que não faz parte
  deste relatório).

  *Objetivo do capítulo:* transformar o diagnóstico dos capítulos 2 a 4 em cenários de qualidade concretos e
  verificáveis, priorizá-los e perceber como os atributos se afetam uns aos outros.

  *Princípio central:* a caracterização dos cenários de qualidade *deve basear-se na identificação de fragilidades do
  sistema atual*. Cada cenário parte de uma fragilidade concreta, com evidência (`EV-nn`), observada na solução de
  base (e.g., uma falha sem recuperação, um ponto de contenção, uma dependência rígida). Um cenário sem fragilidade
  identificada é uma preferência, não uma necessidade. Reutilizem os `EV`, `H` e `ALT` já usados, sem os alterar.

  *Este é o único sítio onde os cenários de qualidade se caracterizam:* os capítulos 6 a 10 usam-nos sem os reescrever.
]

== Cenários de qualidade para a extensão de vídeo

#orientacao[
  Para cada fragilidade relevante, escrevam um cenário com os *seis elementos*:
  - *fonte do estímulo*: quem ou o que o origina (utilizador, serviço, falha de infraestrutura);
  - *estímulo*: o evento a que o sistema tem de reagir;
  - *artefacto*: a parte do sistema afetada;
  - *ambiente*: em que condições (carga normal, pico, degradado);
  - *resposta*: o que o sistema deve fazer;
  - *medida da resposta*: como se verifica, com métrica e escala. Definem-na vocês e tem de ser *verificável*.

  A coluna *Fragilidade* liga o cenário à evidência que o justifica. Não inventem valores de _baseline_, alvo ou
  mínimo: esses fixam-se após a medição inicial. A medida da resposta indica o que se mede, não o valor a atingir.
]

#tab([Cenários de qualidade],
  tabela(
    colunas: (1.2cm, 3.4cm, 2.6cm, 2.2cm, 2.2cm, 2.4cm, 2.2cm, 2.6cm, 3cm),
    tamanho: 7.5pt,
    [ID], [Fragilidade na base (EV-nn)], [Característica (ISO/IEC 25010)], [Fonte do estímulo], [Estímulo], [Artefacto], [Ambiente], [Resposta], [Medida da resposta],
    [QS-01], [Um consumidor para a fila de vídeo (`EV-04`, `EV-05`, `EV-08`)], [Eficiência de desempenho, capacidade], [Cliente HTTP], [Submete B durante a legendagem de A], [`video_queue` e `video_tool`], [Docker, carga concorrente], [B inicia durante A], [Espera média de B ≤ 15 s.],
    [QS-02], [Estado de apresentação volátil (`EV-10`)], [Usabilidade, operabilidade], [Utilizador premium], [Alterna projetos e recarrega durante A], [Dashboard e rota de estado], [Chrome, 1280 × 720], [Mantém acesso e recupera o progresso], [12/12 ações; recuperação em 3/3 ensaios para navegação, recarregamento e reconexão; zero falsas conclusões.],
    [QS-03], [A base usa ack manual (`EV-04`).], [Fiabilidade, recuperabilidade], [Falha de infraestrutura], [Interrompe um worker ou o broker a meio do lote], [RabbitMQ, worker e orquestrador], [Falha transitória], [Retoma após restabelecimento], [Resultado íntegro e zero novos artefactos parciais órfãos. O seguimento verificou os dois tipos de falha.],
  ),
)
]

#orientacao[
  *Priorização.* Avaliem cada cenário em duas dimensões: a *importância para os stakeholders* (quem sofre com a
  fragilidade e quanto) e a *dificuldade ou risco técnico* de a resolver. Justifiquem cada avaliação em poucas palavras
  e atribuam uma ordem de prioridade (1 = mais prioritário). Os dois cenários mais prioritários, e que dão origem aos
  candidatos a RNF do capítulo 6, são os mais importantes e viáveis, não necessariamente os mais fáceis.
]

#tab([Priorização dos cenários],
  tabela(
    colunas: (1.6cm, 4.8cm, 4.8cm, 2cm),
    [ID], [Importância para os stakeholders], [Dificuldade / risco técnico], [Prioridade],
    [QS-01], [Alta, afeta outros utilizadores.], [Média, requer escala e proteção de fechos concorrentes.], [1],
    [QS-02], [Alta, afeta edição e acompanhamento.], [Média a alta, envolve persistência e cliente.], [2],
    [QS-03], [Média, afeta robustez operacional.], [Alta, exige ensaio de falha dedicado.], [3],
  ),
)

== Atributos de qualidade por ordem de prioridade

#orientacao[
  Com base nos cenários mais importantes, ordenem os atributos de qualidade (ISO/IEC 25010) do mais para o menos
  prioritário, indicando os cenários que justificam cada posição. A ordem tem de ser coerente com a tabela de
  priorização acima.
]

+ Capacidade (QS-01). Um consumidor ocupado transmite a espera a outros projetos.
+ Operabilidade (QS-02). Os trabalhos longos exigem navegação e recuperação do estado.
+ Recuperabilidade (QS-03). Uma interrupção a meio do lote exige validação própria.

== Pré-requisitos e efeitos colaterais entre atributos

#orientacao[
  Os atributos não são independentes. Identifiquem os pares em que melhorar um é *pré-requisito* do outro (e.g.,
  observabilidade antes de otimizar desempenho), em que há *sinergia*, ou em que há *conflito* (melhorar um degrada
  o outro). Expliquem a razão e, se possível, citem evidência.
]

#tab([Pré-requisitos e efeitos colaterais entre atributos],
  tabela(
    colunas: (2.8cm, 2.8cm, 4cm, 1fr),
    [Atributo A], [Atributo B], [Efeito (pré-requisito, sinergia ou conflito)], [Razão / evidência],
    [Capacidade], [Integridade do lote], [Risco], [Resultados podem terminar em simultâneo. P-02 verificou a correção.],
    [Operabilidade], [Utilização de recursos], [Custo], [Persistência e consultas periódicas acrescentam tráfego.],
  ),
)

== Recomendações de melhoria à solução atual

#orientacao[
  Recomendações concretas que respondem às fragilidades identificadas, indicando o atributo que melhoram, o padrão
  (global ou vídeo) a que se aplicam, o esforço estimado e o risco de regressão. Esta fase é de _refactoring_: as
  recomendações têm de poder ser aplicadas sem acrescentar funcionalidades.
]

#tab([Recomendações de melhoria],
  tabela(
    colunas: (1fr, 2.6cm, 3cm, 1.8cm, 2.2cm),
    tamanho: 8.5pt,
    [Recomendação], [Atributo(s)], [Padrão a que se refere (global / vídeo)], [Esforço], [Risco de regressão],
    [Escalar o worker e proteger fechos simultâneos.], [Capacidade e fiabilidade], [Vídeo e orquestração], [Médio], [Médio],
    [Persistir e reconciliar o estado no dashboard.], [Operabilidade], [Interação frontend e backend], [Médio], [Médio],
  ),
)
