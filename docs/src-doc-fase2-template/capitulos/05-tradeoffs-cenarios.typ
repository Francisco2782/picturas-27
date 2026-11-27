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

Os três cenários de qualidade (`QS-01` a `QS-03`) derivam das três fragilidades concretas
observadas na base: o bloqueio de cabeça de fila no consumidor único de vídeo (`EV-04`, `EV-05`, `EV-08`), o _overlay_ bloqueante com estado volátil na interface (`EV-10`) e a
ausência de verificação de recuperação perante quedas a meio do processamento (`EV-04`). Assim,  `QS-01` e `QS-02` correspondem às fragilidades
que originaram os candidatos selecionados (`CAND-1` e `CAND-2`) e as decisões `DA-1` e `DA-2`. Já `QS-03` acompanha `DA-1` como cenário de regressão suplementar, verificando que a configuração concorrente preserva o
comportamento do lote perante interrupções de _worker_ ou do _broker_.




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
    [QS-01], [Consumidor único e `prefetch_count=1` geram bloqueio de cabeça de fila (`EV-04`, `EV-05`, `EV-08`)], [Eficiência de desempenho, capacidade], [Cliente HTTP], [Submete projeto B durante a legendagem longa de A], [`video_queue` e `video_tool`], [Docker Compose, carga concorrente], [B inicia sem aguardar pelo término de A], [Tempo entre a submissão de B e o primeiro arranque do seu processamento (`b_wait_seconds`), em segundos, média de três medições válidas; alvo e mínimo fixados após a baseline (cap. 6).],
    [QS-02], [_Overlay_ bloqueante e estado de progresso volátil na UI (`EV-10`)], [Usabilidade, operabilidade], [Utilizador premium], [Alterna projetos e recarrega ou reconecta durante A], [Dashboard, gateway e rota de estado], [Chromium, 1280 × 720, execução ativa], [Mantém edição navegável e recupera o progresso], [Número de ações A/B concluídas por ensaio (0–4, três ensaios) e recuperações do acompanhamento por percurso (navegação, recarregamento, reconexão), sem conclusões falsas.],
    [QS-03], [Ack manual sem recuperação verificada perante queda a meio do lote (`EV-04`)], [Fiabilidade, recuperabilidade], [Falha de infraestrutura], [Interrompe um worker ou o _broker_ a meio do processamento], [RabbitMQ, `video_tool` e `projects`], [Falha transitória controlada], [Retoma o trabalho após restabelecimento], [O mesmo trabalho é retomado e concluído, o resultado final é íntegro e descarregável e não ficam novos ficheiros de _staging_ órfãos após cada interrupção.],
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
    [QS-01], [Alta: o bloqueio de fila atrasa todos os outros utilizadores em fila.], [Média: exige escala de réplicas e proteção contra corrida no fecho concorrente (`H-01`).], [1],
    [QS-02], [Alta: impede a navegação e destrói a visibilidade em tarefas longas.], [Média a alta: envolve persistência atómica no backend e reconciliação no cliente.], [2],
    [QS-03], [Média: afeta a robustez operacional perante quedas transitórias.], [Alta: exige injeção controlada de falhas e verificação dedicada em ambiente isolado.], [3],
  ),
)

A ordem de prioridade resulta do cruzamento das duas dimensões avaliadas. `QS-01` e `QS-02` ocupam os primeiros lugares
porque combinam a maior importância com uma dificuldade média: a espera de B atrás de A atrasa qualquer projeto submetido
durante uma legendagem, e o _overlay_ com estado volátil impede o utilizador de continuar a trabalhar durante toda a
execução. Ambas as dores manifestam-se na utilização normal do sistema, sem que seja preciso qualquer falha e os
caminhos de resolução eram conhecidos e acessíveis (réplicas concorrentes na fila existente; persistência do estado de
execução). `QS-03` fica em terceiro lugar pelas duas dimensões em simultâneo: a importância é média, porque a
fragilidade só se concretiza perante quedas transitórias de infraestrutura, fora do caminho feliz, e a confirmação
manual já protege a tarefa na maioria das situações. Além disso, a dificuldade é alta, porque a sua verificação exige injeção
controlada de falhas num ambiente isolado, com observação da reentrega da mensagem e dos ficheiros de _staging_. 

== Atributos de qualidade por ordem de prioridade

#orientacao[
  Com base nos cenários mais importantes, ordenem os atributos de qualidade (ISO/IEC 25010) do mais para o menos
  prioritário, indicando os cenários que justificam cada posição. A ordem tem de ser coerente com a tabela de
  priorização acima.
]

+ *Capacidade* (`QS-01`): um consumidor ocupado propaga o tempo bloqueado a todos os projetos em espera.
+ *Operabilidade* (`QS-02`): execuções longas exigem continuidade de trabalho e recuperação fiável do estado.
+ *Recuperabilidade* (`QS-03`): interrupções a meio do lote requerem retoma limpa sem artefactos órfãos.

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
    [Capacidade], [Fiabilidade (integridade do lote)], [Conflito (risco de concorrência)], [Processar vídeos em paralelo permite fechos simultâneos sobre o mesmo lote, exigindo proteção atómica (`H-01`, validada em P-02).],
    [Operabilidade], [Eficiência (utilização de recursos)], [Conflito], [Persistir o estado no MongoDB e consultar a rota de estado acrescentam escritas e tráfego HTTP (`EV-06`, `EV-07`).],
    [Observabilidade do estado], [Operabilidade], [Pré-requisito], [A interface só consegue recuperar o progresso após navegação ou recarregamento se o backend persistir e expuser o estado (`EV-06`, `EV-07`).],
    [Capacidade], [Eficiência de desempenho, utilização de recursos], [Conflito], [Réplicas concorrentes aumentam o pico de RAM agregado (+1,39 GB medidos entre a base repetida e o final, cap. 10); o custo é gerido mantendo uma réplica por omissão no Compose (`EV-08`, `DA-1`).],
    [Fiabilidade (retoma, `QS-03`)], [Capacidade (`QS-01`)], [Sinergia], [A retoma após interrupção de _worker_ e de _broker_ foi verificada com duas réplicas ativas e carga real, provando que o desenho de recuperação funciona precisamente na configuração concorrente que `DA-1` introduz.],
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
    [Escalar `video_tool` para consumidores concorrentes e proteger fechos simultâneos de lote.], [Capacidade e fiabilidade], [Padrão do vídeo e orquestração global], [Médio], [Médio],
    [Persistir o _snapshot_ de execução, remover o _overlay_ bloqueante e reconciliar estado no dashboard.], [Operabilidade], [Interação frontend e orquestrador], [Médio], [Médio],
    [Manter a confirmação manual no _worker_ de vídeo e verificar a retoma perante interrupção do _worker_ ou do _broker_, com limpeza de _staging_ órfão (cenário de regressão associado a `DA-1`).], [Fiabilidade], [Padrão do vídeo e _broker_], [Médio], [Baixo],
  ),
)


