#import "../template.typ": *

// Capítulo inteiro na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Cenários de Entrada e Táticas Candidatas

#orientacao[
  *Origem:* Exercício 7, secções 1 e 2 do _template_.

  *Objetivo do capítulo:* partir dos dois cenários já caracterizados e identificar as táticas arquiteturais que os podem
  melhorar. Os cenários vêm do capítulo 5 e os candidatos do capítulo 6 (`QS-nn`, `CAND-n`) e *não são reescritos*: o
  capítulo 5 é o único sítio onde os cenários se caracterizam. Se tiverem de corrigir uma medida da resposta, corrijam-na
  no capítulo 5 e registem a alteração na secção 7.2.

  Nas tabelas seguintes, `QS-01` e `QS-02` designam os cenários de `CAND-1` e `CAND-2`: substituam-nos pelos IDs reais.
]

== Candidatos e cenários de entrada

O ponto de partida para a conceção arquitetural assenta nos dois cenários formais previamente selecionados e especificados, resumidos na @tab-cenarios-entrada sem qualquer adulteração das suas medidas e condições originais.

#tab([Candidatos e cenários de entrada],
  tabela(
    colunas: (1.6cm, 1.8cm, 3.2cm, 1.8cm, 3.2cm, 3.4cm, 3.8cm, 3.8cm),
    tamanho: 8pt,
    [Candidato], [Cenário (`QS-nn`)], [Característica / subcaracterística (ISO/IEC 25010)], [Evidência], [Origem (padrão global / vídeo / interação)], [Estímulo a que a tática reage], [Resposta e medida (resumo)], [Escala e método (cap. 6)],
    [CAND-1], [QS-01], [Eficiência de desempenho: capacidade], [`EV-02`, `EV-03`, `EV-06`], [Trabalhador `video_tool` monolítico com fila única], [Submissão de projeto B (3 vídeos com brilho) logo após projeto A (legendas de 177 s).], [Processamento de B arranca de imediato sem ter de aguardar pelo término da transcrição de A; espera de B $<= 15$ s.], [Segundos decorridos entre submissão e primeiro arranque de B (`b_wait_seconds`) em harness automatizado A/B.],
    [CAND-2], [QS-02], [Usabilidade: operabilidade], [`EV-08`, `EV-04`, `EV-05`], [Interação entre orquestrador backend e frontend React SPA], [Utilizador navega para outro projeto, usa a toolbar, regressa e recarrega a página durante a execução ativa.], [Interface mantém-se navegável sem modais bloqueantes, recuperando o progresso e percentagem reais.], [Ações concluídas (0-12) e taxas de recuperação após navegação (3/3) e refresh (3/3) em ensaio no Chromium.],
  ),
) <tab-cenarios-entrada>

== Alterações feitas ao capítulo 5 (se existirem)

Em estrito cumprimento das diretrizes metodológicas, os cenários QS-01 e QS-02 mantiveram-se inalterados na sua formulação, métricas e valores de referência. No âmbito de QS-02, a verificação experimental estendeu a observação à recuperação após perda e restabelecimento explícito de ligação de rede (reconexão WebSocket), confirmando o comportamento pretendido sem desvio das regras do cenário.

#tab([Alterações aos cenários],
  tabela(
    colunas: (2cm, 1fr, 4cm),
    [Cenário], [O que mudou e porquê], [Onde foi atualizado],
    [QS-01], [Nenhuma alteração na formulação, métricas ou valores de referência.], [Capítulo 5 mantido integralmente.],
    [QS-02], [Nenhuma alteração às regras base; verificação alargada à reconexão de rede.], [Capítulo 5 mantido integralmente.],
  ),
)

== Táticas candidatas

#orientacao[
  Identifiquem *pelo menos três táticas por cenário*, de categorias de atributo adequadas (e.g., Desempenho → gerir
  recursos; Disponibilidade → recuperar de falhas). Para cada tática, expliquem como produz a resposta pretendida
  (estímulo → tática → resposta) e se já existe, total ou parcialmente, na base (com evidência).

  Classifiquem cada tática: *A* = _refactoring_ puro; *B* = alteração visível que é o objeto da melhoria; *C* =
  funcionalidade nova, a *rejeitar* nesta fase. Táticas de classe C podem constar da lista, mas não podem ser escolhidas.
]

Para responder a cada cenário, foram identificadas três táticas arquiteturais concorrentes, enquadradas nas categorias formais de desenho de software de Bass, Clements & Kazman. As táticas foram classificadas segundo a sua natureza: *Classe A* (_refactoring_ estrutural puro sem impacto visível no utilizador); *Classe B* (alteração visual justificada por ser o próprio objeto da melhoria de usabilidade); ou *Classe C* (introdução de funcionalidade nova, estritamente rejeitada nesta fase). As táticas encontram-se sistematizadas na @tab-taticas-candidatas.

#tab([Táticas candidatas],
  tabela(
    colunas: (1.5cm, 1.6cm, 3.4cm, 3.4cm, 5.2cm, 3.6cm, 1.6cm),
    tamanho: 8pt,
    [ID], [Cenário], [Atributo → categoria], [Tática], [Como produz a resposta (estímulo → tática → resposta)], [Já existe na base? (evidência)], [Classe (A/B/C)],
    [TAT-01], [QS-01], [Desempenho: gerir recursos], [#strong[Replicar computação (_Replicate computation_)]], [O broker distribui as mensagens de vídeo pendentes por múltiplas réplicas ativas na mesma fila (`video_queue`), permitindo que a réplica livre processe o lote B enquanto a outra transcreve o lote A.], [Parcial: o RabbitMQ suporta nativamente, mas o Compose definia apenas 1 réplica (`EV-06`).], [#strong[A]],
    [TAT-02], [QS-01], [Desempenho: controlar procura], [#strong[Priorizar eventos / Filas segregadas (_Prioritize events_)]], [Segrega o tráfego em duas filas (`video_light_queue` e `video_heavy_queue`), garantindo que tarefas rápidas de fotogramas têm trânsito prioritário e não esperam por legendas.], [Não: existe apenas a fila durável única `video_queue` para todas as tarefas de vídeo (`EV-01`).], [#strong[A]],
    [TAT-03], [QS-01], [Desempenho: reduzir sobrecarga], [#strong[Partilha de recursos em memória (_Reduce overhead_)]], [Partilha instâncias do modelo Faster-Whisper entre processos para diminuir a pegada de RAM e eliminar a sobrecarga de carregamento a cada nova réplica.], [Parcial: modelos partilhados em volume de disco; cada processo gere a sua instância via `lru_cache`.], [#strong[A]],
    [TAT-04], [QS-02], [Usabilidade / Fiabilidade: gerir recursos], [#strong[Manter cópias de dados (_Maintain data copies_)]], [O orquestrador persiste no MongoDB um snapshot atómico (`processingRun`) contendo token, estado e progresso monotónico, projetado numa rota REST segura.], [Não: a base mantinha o progresso apenas na memória volátil do componente React (`EV-08`).], [#strong[A]],
    [TAT-05], [QS-02], [Usabilidade: apoiar tarefas concorrentes], [#strong[Desacoplamento visual da interface (_Support concurrent tasks_)]], [Elimina a janela modal de sobreposição bloqueante e integra uma barra de progresso flutuante no layout global do Dashboard, permitindo navegação concorrente.], [Não: a interface original bloqueava o ecrã com um modal obrigatório durante o lote (`EV-08`).], [#strong[B]],
    [TAT-06], [QS-02], [Usabilidade / Fiabilidade: detetar e recuperar], [#strong[Reconciliação e sincronização de eventos (_Event synchronization_)]], [O cliente reconcilia os eventos recebidos via Socket.IO com chamadas periódicas à API de estado, ordenando por timestamp e token para evitar regressões.], [Não: o cliente original não validava tokens nem dispunha de reconciliação de rede (`EV-08`).], [#strong[A]],
  ),
) <tab-taticas-candidatas>
]
