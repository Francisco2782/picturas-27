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

A partir das fragilidades e dos estrangulamentos identificados no diagnóstico arquitetural da solução herdada da Fase 1, foram caracterizados três cenários de qualidade formais segundo os seis elementos estruturais da engenharia de software (Fonte, Estímulo, Artefacto, Ambiente, Resposta e Medida da Resposta), detalhados na @tab-cenarios-qualidade.

#tab([Cenários de qualidade],
  tabela(
    colunas: (1.3cm, 3.2cm, 2.6cm, 2.2cm, 2.6cm, 2.4cm, 2.2cm, 3.2cm, 3.6cm),
    tamanho: 7.5pt,
    [ID], [Fragilidade (`EV-nn`)], [Atributo de qualidade], [Fonte do estímulo], [Estímulo], [Artefacto afetado], [Ambiente], [Resposta], [Medida de resposta],
    [QS-01], [Consumidor único com prefetch unitário (`EV-02`, `EV-03`, `EV-06`). A legendagem longa em CPU bloqueia a fila.], [Eficiência de desempenho: capacidade], [Cliente HTTP / API externa], [Submissão de projeto B (3 vídeos com brilho) 1 a 2 s após projeto A (legendagem de 177 s).], [Fila durável `video_queue` e trabalhador `video_tool`.], [Carga concorrente em contentores Docker.], [O processamento de B arranca de imediato sem ter de aguardar pelo término de A.], [Tempo de espera de B (`b_wait_seconds`) $<= 15$ s em média (0,113 s obtidos no ensaio final).],
    [QS-02], [Progresso mantido em memória volátil e modal sobreposto bloqueante no ecrã (`EV-08`).], [Usabilidade: operabilidade], [Utilizador autenticado no navegador], [Navegação para outro projeto, uso da toolbar, regresso e recarregamento (F5) durante o lote ativo.], [Painel React Next.js e rota de estado de `projects`.], [Sessão no Chromium (1280x720) durante legendas ativas.], [Interface permanece responsiva e recupera progresso e estado real sem falsas conclusões.], [12/12 ações concluídas; recuperação de 3/3 em navegação e 3/3 em refresh; 0 conclusões prematuras.],
    [QS-03], [Risco de perda de mensagens e resíduos órfãos em falhas transitórias (`EV-02`, `EV-07`).], [Fiabilidade: recuperabilidade], [Falha de infraestrutura operacional], [Interrupção abrupta do contentor `video_tool` ou reinício do broker RabbitMQ a meio do lote.], [Trabalhador `video_tool`, RabbitMQ e `projects`.], [Falha transitória com recuperação de ligação.], [Retoma a subscrição, reprocessa o lote sem duplicados e limpa ficheiros `.part` residuais.], [100% dos trabalhos concluídos com sucesso; 0 ficheiros parciais órfãos no volume partilhado.],
  ),
) <tab-cenarios-qualidade>
]

#orientacao[
  *Priorização.* Avaliem cada cenário em duas dimensões: a *importância para os stakeholders* (quem sofre com a
  fragilidade e quanto) e a *dificuldade ou risco técnico* de a resolver. Justifiquem cada avaliação em poucas palavras
  e atribuam uma ordem de prioridade (1 = mais prioritário). Os dois cenários mais prioritários, e que dão origem aos
  candidatos a RNF do capítulo 6, são os mais importantes e viáveis, não necessariamente os mais fáceis.
]

A priorização dos cenários orientou-se por dois eixos fundamentais: a *importância e impacto real para os stakeholders* (utilizadores da aplicação e operadores da infraestrutura) e a *dificuldade ou risco técnico* associado à intervenção de _refactoring_, resumida na @tab-priorizacao-cenarios.

#tab([Priorização dos cenários],
  tabela(
    colunas: (1.6cm, 4.8cm, 4.8cm, 2cm),
    [ID], [Importância para os stakeholders], [Dificuldade / risco técnico], [Prioridade final],
    [QS-01], [*Crítica*: o bloqueio total da fila de vídeo por trabalhos pesados inviabiliza o serviço em regime multi-utilizador, degradando a perceção de utilidade do produto.], [*Média*: requer escalamento horizontal em Docker Compose e resolução rigorosa de condições de corrida na finalização de lotes em `projects`.], [*1* (Selecionado)],
    [QS-02], [*Elevada*: aprisionar o utilizador num ecrã modal durante minutos e perder o estado ao navegar ou recarregar a página compromete a usabilidade básica.], [*Média a Alta*: exige persistência atómica no MongoDB (`processingRun`), projeção de rota REST protegida e reconciliação assíncrona no cliente React.], [*2* (Selecionado)],
    [QS-03], [*Média*: relevante para a resiliência operacional contínua, mas a solução de base já dispunha de confirmação manual (`ack`) e escrita temporária atómica.], [*Alta*: requer testes complexos de injeção de falhas e gestão de reconexão de brokers em contexto de concorrência.], [*3* (Suporte)],
  ),
) <tab-priorizacao-cenarios>

== Atributos de qualidade por ordem de prioridade

#orientacao[
  Com base nos cenários mais importantes, ordenem os atributos de qualidade (ISO/IEC 25010) do mais para o menos
  prioritário, indicando os cenários que justificam cada posição. A ordem tem de ser coerente com a tabela de
  priorização acima.
]

A ordenação fundamentada dos atributos de qualidade da norma ISO/IEC 25010 decorre diretamente da análise de impacto dos cenários:

1. *Eficiência de Desempenho — Capacidade (cenário QS-01)*: Constitui o estrangulamento arquitetural mais gravoso da versão herdada. A serialização forçada (`prefetch_count=1`, réplica única) anula qualquer paralelismo real, provocando filas de espera insustentáveis quando surgem tarefas de IA.
2. *Usabilidade — Operabilidade (cenário QS-02)*: O processamento de vídeo é inerentemente demorado; bloquear a interface com uma janela modal e destruir a visibilidade da execução perante um simples recarregamento de página anula a usabilidade prática da plataforma.
3. *Fiabilidade — Recuperabilidade (cenário QS-03)*: Garante que eventuais interrupções transitórias no contentor de execução ou no _broker_ de mensagens não originem perda irrecuperável de trabalhos nem corrupção do sistema de ficheiros partilhado.

== Pré-requisitos e efeitos colaterais entre atributos

#orientacao[
  Os atributos não são independentes. Identifiquem os pares em que melhorar um é *pré-requisito* do outro (e.g.,
  observabilidade antes de otimizar desempenho), em que há *sinergia*, ou em que há *conflito* (melhorar um degrada
  o outro). Expliquem a razão e, se possível, citem evidência.
]

Os atributos de qualidade não são estanques, existindo relações complexas de sinergia, pré-requisito e conflito arquitetural entre eles, detalhadas na @tab-tradeoffs-atributos.

#tab([Pré-requisitos e efeitos colaterais entre atributos],
  tabela(
    colunas: (2.8cm, 2.8cm, 3.2cm, 1fr),
    [Atributo A], [Atributo B], [Efeito cruzado (conflito ou sinergia)], [Justificação],
    [Capacidade (QS-01)], [Fiabilidade / Integridade], [Conflito e Risco], [O processamento concorrente por múltiplas réplicas aumenta o risco de condições de corrida quando vídeos do mesmo lote terminam em simultâneo no orquestrador `projects` (defeito F1 reproduzido e resolvido na prova P-02).],
    [Capacidade (QS-01)], [Utilização de Recursos], [Conflito observado], [A instanciação de duas réplicas elevou a média dos picos agregados de RAM de 2,86 GB para 4,29 GB (duplicação de instâncias Faster-Whisper), embora a média do pico de CPU tenha permanecido sobreposta (~738% a 756%).],
    [Operabilidade (QS-02)], [Fiabilidade / Consistência], [Pré-requisito], [Para apresentar o progresso fidedigno e recuperá-lo resilientemente após navegação ou recarregamento, é indispensável persistir atomicamente snapshots no MongoDB com validação monotónica de progresso (`EV-04`).],
    [Operabilidade (QS-02)], [Eficiência de Desempenho], [Conflito moderado], [A consulta periódica de estado (_polling_) e a reconciliação cliente-servidor adicionam pedidos HTTP à API (medidos em 4 pedidos adicionais e 1048 bytes num intervalo de 4 segundos a 1 Hz).],
  ),
) <tab-tradeoffs-atributos>

== Recomendações de melhoria à solução atual

#orientacao[
  Recomendações concretas que respondem às fragilidades identificadas, indicando o atributo que melhoram, o padrão
  (global ou vídeo) a que se aplicam, o esforço estimado e o risco de regressão. Esta fase é de _refactoring_: as
  recomendações têm de poder ser aplicadas sem acrescentar funcionalidades.
]

Com base no diagnóstico rigoroso dos cenários prioritários e nos seus _trade-offs_, formularam-se quatro recomendações concretas de _refactoring_ sem introdução de novas funcionalidades, apresentadas na @tab-recomendacoes-melhoria.

#tab([Recomendações de melhoria],
  tabela(
    colunas: (1fr, 2.8cm, 3.2cm, 1.8cm, 2.2cm),
    tamanho: 8.5pt,
    [Recomendação], [Atributo(s) beneficiado(s)], [Risco ou custo associado], [Impacto no padrão global], [Prioridade (MoSCoW)],
    [Configurar 2 réplicas concorrentes de `video_tool` na mesma fila `video_queue` com prefetch unitário.], [Capacidade e Comportamento temporal], [Duplicação de RAM em pico], [Mantém o padrão global e a fila], [#must],
    [Sincronizar atomicamente a consolidação de lotes e criação de registos `Process` em `projects/utils/processBatch.js`.], [Fiabilidade e Integridade de dados], [Risco de contenção de escrita no MongoDB], [Mantém], [#must],
    [Persistir o modelo `processingRun` no MongoDB e disponibilizar rota autenticada de projeção segura de estado.], [Operabilidade e Fiabilidade], [Custo negligenciável de I/O de snapshot], [Mantém], [#must],
    [Substituir o modal sobreposto bloqueante por um painel flutuante global no layout do Dashboard com reconciliação assíncrona.], [Usabilidade e Operabilidade], [Risco de dessincronização em polling lento], [Mantém], [#must],
  ),
) <tab-recomendacoes-melhoria>
