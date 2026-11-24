#import "../template.typ": *

#paisagem[
= Trade-offs, Medição e Preservação Funcional

#orientacao[
  *Origem:* Exercício 7, secção 5 do _template_ (e os riscos de preservação funcional do Bloco 2, secção 6).

  *Objetivo do capítulo:* mostrar que as decisões foram avaliadas além do atributo que melhoram (_trade-offs_), que a
  melhoria foi medida de forma comparável (antes e depois) e que o comportamento funcional foi preservado.

  A mesma medição é feita *antes e depois* do _refactoring_, no mesmo ambiente. *Não inventem valores* de _baseline_, alvo
  ou mínimo aceitável: fixam-se após a medição inicial. Guardem os _scripts_, os dados e o ambiente das medições para os
  reutilizar como _baseline_.
]

== Matriz de efeitos

#orientacao[
  Para cada decisão, indiquem se cada atributo *melhora* (↑), *degrada* (↓) ou fica *neutro* (=), e justifiquem. Incluam
  no mínimo quatro atributos, e entre eles a característica do outro cenário: uma melhoria num atributo costuma ter um
  custo noutro, e é isso que esta matriz deve revelar. Se uma decisão degradar um atributo, digam como a equipa vai
  gerir esse custo.
]

A avaliação de _trade-offs_ da @tab-matriz-efeitos sistematiza o impacto multidimensional de cada decisão arquitetural sobre os atributos de qualidade da norma ISO/IEC 25010, evidenciando os ganhos alcançados e os custos operacionais assumidos.

#tab([Matriz de efeitos das decisões],
  tabela(
    colunas: (1.8cm, 2.8cm, 3.2cm, 2.4cm, 2.4cm, 3.4cm, 1fr),
    tamanho: 8pt,
    [Decisão], [Desempenho], [Disponibilidade / Fiabilidade], [Segurança], [Usabilidade], [Manutenibilidade / Testabilidade], [Justificação],
    [DA-1 (Consumidores concorrentes)], [#strong[$arrow.t$ Ganho drástico] no tempo de espera de B (0,113 s). $arrow.b$ Acréscimo de RAM agregada (+1,43 GB).], [#strong[$arrow.t$ Tolerância]: P-02 comprovou a integridade de dois fechos simultâneos sem perda de ficheiros.], [#strong[$=$ Neutro]: mantém intactas as interfaces públicas e perímetros de rede.], [#strong[$arrow.t$ Indireto]: os pedidos subsequentes iniciam a execução sem esperas.], [#strong[$arrow.b$ Mais caminhos]: exige cobertura rigorosa de testes de concorrência e sincronização.], [Duas réplicas de `video_tool` consomem em paralelo da mesma fila durável com prefetch unitário.],
    [DA-2 (Snapshot e UI não bloqueante)], [#strong[$arrow.b$ Sobrecarga moderada]: acréscimo de escritas no MongoDB e chamadas periódicas de polling na API.], [#strong[$arrow.t$ Recuperabilidade]: taxa de 3/3 na recuperação de estado após refresh, navegação e perda de rede.], [#strong[$arrow.t$ Controlos]: validação de permissões de cancelamento por utilizador (correção F8).], [#strong[$arrow.t$ Pleno sucesso]: 12/12 ações concluídas em Chromium sem modais bloqueantes.], [#strong[$arrow.t$ Modularidade]: componentes desacoplados com testes unitários de reconciliação monotónica.], [O snapshot atómico (`processingRun`) desvincula o estado da interface da sessão volátil do cliente.],
  ),
) <tab-matriz-efeitos>
]

== Interação entre DA-1 e DA-2

As duas decisões arquiteturais complementam-se mutuamente no ciclo de vida dos pedidos:
- *Sinergia de utilização:* A redução do tempo de espera permitida por DA-1 ganha pleno valor para o utilizador final graças a DA-2. Enquanto um vídeo longo está a ser transcrito numa réplica e outro projeto avança na segunda réplica, o utilizador pode alternar livremente entre os dois dashboards, acompanhar o progresso real de ambos em simultâneo e editar novos pipelines sem interrupção.
- *Interdependência técnica e concorrência:* A existência de múltiplas réplicas em DA-1 intensifica o volume de eventos de progresso e conclusões concorrentes recebidas pelo orquestrador `projects`. Isto torna imperativa a arquitetura de DA-2, que garante a validação monotónica de percentagens por token e a precedência estrita dos estados terminais (`COMPLETED`, `FAILED`), impedindo que eventos fora de ordem corrompam a visualização.

#tab([Interação entre as decisões],
  tabela(
    colunas: (2.2cm, 2.2cm, 4.4cm, 1fr),
    [Decisão A], [Decisão B], [Efeito (pré-requisito, sinergia ou conflito)], [Razão / evidência],
    [DA-1], [DA-2], [Sinergia e Complementaridade], [A redução da espera alcançada por DA-1 só é plenamente usufruível com a interface não bloqueante de DA-2, que permite ao utilizador navegar e operar concorrentemente.],
    [DA-2], [DA-1], [Pré-requisito para Concorrência Segura], [A presença de múltiplas réplicas de vídeo aumenta os eventos de progresso concorrentes, exigindo a validação monotónica de snapshots de DA-2 para evitar corrupção visual.],
  ),
)

== Plano de medição

Para assegurar a comparabilidade científica entre as medições *Antes* e *Depois*, os ensaios foram executados sob as condições estritas descritas na @tab-plano-medicao.

#tab([Plano de medição],
  tabela(
    colunas: (1.5cm, 3.4cm, 3.2cm, 2.6cm, 2.6cm, 2.8cm),
    tamanho: 8pt,
    [Cenário], [Cenário de teste e carga], [Ambiente (máquina, recursos, versões)], [O que se regista], [Repetições e agregação], [Onde ficam os _scripts_ e os dados],
    [QS-01], [Projeto A (fala de 177 s com `subtitles`). Projeto B (dois MP4 de 10 s e um MOV de 6 s com `brightness`) submetido 1,5 s após A.], [Host i7-13650HX (20 CPUs lógicas), 33,36 GB RAM no Docker, Engine 29.9.3, Compose v5.7.1.], [Timestamps de pedidos, início e fim no worker, `b_wait_seconds`, profundidade de fila e picos de CPU e RAM.], [1 ensaio de aquecimento + 3 ensaios válidos. Cálculo de média e amplitude.], [`evaluation/run_scenario.py` e arquivo `evaluation/evidence/picturas-phase2-d01.tar.gz`.],
    [QS-02], [Projeto A inicia legendas em vídeo de 10 s. Utilizador acede ao Projeto B, usa a toolbar, regressa a A, recarrega a página (F5) e simula perda de rede.], [Navegador Chromium (1280x720), conta premium autenticada, rede local HTTPS (:8080).], [Taxa de sucesso em 4 ações/ensaio, taxa de recuperação após navegação, refresh e reconexão; falsas conclusões.], [1 ensaio de aquecimento + 3 ensaios válidos protocolados no Chromium.], [Script `browser_u04.py` e manifestos no pacote de evidência D-01.],
  ),
) <tab-plano-medicao>

== Resultados das medições

#orientacao[
  Para cada requisito não funcional, apresentem os valores medidos *antes* (_baseline_) e *depois* do _refactoring_, com o
  mesmo método e nas mesmas condições (plano acima), e comparem-nos com o valor-alvo e o valor mínimo aceitável fixados no
  capítulo 6. Os dados brutos e os _scripts_ ficam no repositório entregue.

  Na análise, sejam críticos: o que melhorou, o que não foi atingido e porquê, que outros atributos foram afetados
  (confirmando ou não a matriz de efeitos) e que ameaças à validade das medições existem.
]

Na @tab-resultados-medicoes, confrontam-se os valores medidos na linha de base oficial com os resultados obtidos após o _refactoring_, comparando-os com os limiares quantitativos fixados.

#tab([Resultados das medições],
  tabela(
    colunas: (1.5cm, 1fr, 2cm, 2cm, 2cm, 2cm, 2cm),
    tamanho: 8.5pt,
    [Cenário], [Medição (o que se mede, unidade)], [Antes (_baseline_)], [Depois], [Valor-alvo], [Mínimo aceitável], [Atingido?],
    [QS-01], [Espera média até ao arranque de B (`b_wait_seconds`)], [#strong[61,727 s]], [#strong[0,113 s]], [$<= 15,0$ s], [$<= 30,0$ s], [#strong[Alvo superado]],
    [QS-02], [Ações concluídas em concorrência e recuperação de estado], [#strong[6/12 ações] (50%); navegação: 0/3; refresh: 0/3], [#strong[12/12 ações] (100%); navegação: 3/3; refresh: 3/3; reconexão: 3/3], [12/12 ações; 3/3 nas recuperações], [$>= 3/4$ ações; 3/3 nas recuperações], [#strong[Alvo plenamente atingido]],
  ),
) <tab-resultados-medicoes>

=== Análise crítica dos resultados de Eficiência de Desempenho (Capacidade — QS-01)

A métrica principal `b_wait_seconds` quantifica o tempo decorrido desde o envio da chamada HTTP de submissão do Projeto B até ao primeiro registo em log de processamento de brilho no trabalhador `video_tool`. Na linha de base oficial (uma réplica), o trabalhador permaneceu bloqueado a executar a transcrição do Projeto A durante mais de um minuto, forçando B a aguardar em média 61,727 s. Na configuração final com duas réplicas concorrentes, o primeiro vídeo do Projeto B foi consumido de imediato pela réplica livre, iniciando em escassos #strong[0,113 s] (amplitude entre 0,093 s e 0,132 s nos três ensaios válidos).

Para permitir uma avaliação rigorosa e contextualizada, realizou-se adicionalmente uma repetição da baseline com o mesmo instrumento de recolha final, sintetizada na @tab-comparacao-campanhas.

#tab([Comparação detalhada de desempenho e recursos entre séries de medição],
  tabela(
    colunas: (1fr, 2.4cm, 3.4cm, 3.4cm),
    tamanho: 8.5pt,
    [Métrica de sistema ou de processo], [Baseline oficial (1 worker)], [Baseline repetida (1 worker, mesmo instrumento)], [Final com refactoring (2 workers concorrentes)],
    [Duração do Projeto A (s)], [63,888 s], [85,048 s (82,332 – 86,418)], [80,961 s (78,326 – 84,255)],
    [Duração do Projeto B (s)], [68,374 s], [90,196 s (86,803 – 92,902)], [9,676 s (8,285 – 10,394)],
    [Espera de B (`b_wait_seconds`)], [#strong[61,727 s]], [#strong[82,242 s] (79,325 – 84,393)], [#strong[0,113 s] (0,093 – 0,132)],
    [Duração total do lote / Makespan (s)], [69,925 s], [91,755 s (88,370 – 94,460)], [80,961 s (78,326 – 84,255)],
    [Mensagens na fila pronta (máximo)], [3], [3 (3 – 3)], [2 (2 – 2)],
    [Mensagens por confirmar (unacked, máx.)], [1], [1 (1 – 1)], [2 (2 – 2)],
    [Pico de CPU agregado do grupo (%)], [830,810%], [756,550% (673,600 – 803,450)], [738,700% (660,900 – 821,880)],
    [Pico de memória RAM agregado (GB)], [3,051 GB], [#strong[2,860 GB] (2,848 – 2,869)], [#strong[4,289 GB] (4,014 – 4,442)],
  ),
) <tab-comparacao-campanhas>

*Compromissos e ameaças à validade observados:*
1. *Consumo de memória RAM:* A instanciação de duas réplicas fez subir o pico médio de RAM agregada de 2,86 GB para 4,29 GB (acréscimo de cerca de 1,43 GB, correspondente à duplicação dos modelos Faster-Whisper e bibliotecas de vídeo em memória). Trata-se de um _trade-off_ direto e previsto pela tática de replicação.
2. *Consumo de CPU:* As médias dos picos agregados de CPU (756,5% na base repetida vs. 738,7% no final) exibem sobreposição total nas amplitudes experimentais, demonstrando que a adição do segundo trabalhador não gerou contenção patológica de CPU no host de 20 núcleos.
3. *Variações na duração absoluta:* A baseline repetida apresentou durações absolutas mais longas do que a baseline oficial histórica (85 s vs 63 s em A), explicadas por atualizações nas imagens de contentores e diferenças de rede (acesso em loopback direto vs Nginx externo). Contudo, em ambas as séries com um trabalhador, a espera de B foi sempre superior a 60 s, confirmando que a redução para 0,113 s se deve inequivocamente à segunda réplica ativa.

=== Análise crítica dos resultados de Usabilidade (Operabilidade — QS-02)

Na versão original, a presença da janela modal de sobreposição bloqueava qualquer ação do utilizador e destruía o acompanhamento perante recarregamentos (0/3 recuperações e 6/12 ações concluídas).

Com a introdução do painel desacoplado no layout do Dashboard e da persistência atómica no MongoDB:
- O utilizador concluiu com êxito #strong[12 em 12 ações protocoladas (100%)] em três ensaios independentes.
- A aplicação alcançou taxa de sucesso de #strong[3/3 em recuperação após navegação], #strong[3/3 após recarregamento (F5)] e #strong[3/3 após perda e reconexão de rede], com rigorosamente #strong[zero conclusões prematuras ou estados falsos].
- Em termos de custo na rede, registaram-se 40 pedidos HTTP à API por ensaio no sistema final (face a 28 na base), dos quais 8 corresponderam a consultas à rota `/processing-status` (face a 6 na base).
- Um ensaio complementar com observador a 1 Hz quantificou o custo isolado de polling em 4 chamadas adicionais e 1048 bytes transferidos num intervalo de 4 segundos, com uma latência mediana por pedido de apenas 7,75 ms (6,87 a 9,88 ms), comprovando um impacto negligenciável na infraestrutura.

#pagebreak(weak: true)
== Preservação funcional

A conformidade funcional do sistema PictuRAS foi rigorosamente validada antes e depois de cada alteração de código através de uma bateria abrangente de #strong[128 testes automatizados], distribuídos por múltiplos níveis da arquitetura:
- #strong[38 testes unitários e de integração em Node.js], cobrindo o orquestrador `projects` e a reconciliação no cliente `frontend` (`node --test`);
- #strong[77 testes automatizados em PyTest] no subsistema `Tools/video`, validando codecs de áudio/vídeo, efeitos de cor, cortes, legendagem Faster-Whisper e geração de ficheiros temporários atómicos;
- #strong[14 testes de validação do harness de avaliação] (`evaluation/tests`);
- Compilação limpa de produção do frontend Next.js sem avisos de tipagem ou de _linting_.

Na @tab-preservacao-funcional e na @tab-riscos-mitigacao, detalham-se os cenários de regressão, os defeitos corrigidos e as estratégias de mitigação implementadas.

#tab([Preservação funcional e testes de regressão],
  tabela(
    colunas: (2.4cm, 3.6cm, 3.2cm, 3.4cm, 1fr),
    tamanho: 8pt,
    [Zona alterada], [Testes de regressão existentes (`Tools/video/tests`, `projects/tests`, …)], [Lacunas de teste], [Testes acrescentados], [Resultado (imagem e vídeo)],
    [DA-1: Orquestração em concorrência], [`projects/tests`, `Tools/video/tests`], [Perda de resultados em finalizações de lotes concorrentes (defeito F1).], [Prova controlada com barreiras e ensaio com MongoDB e S3 reais (sessão P-02).], [Dois resultados distintos, íntegros e descarregáveis preservados.],
    [DA-2: Estado e interface web], [Testes do orquestrador e componentes visuais.], [Dessincronização de tokens antigos, recarregamento e permissões.], [Suite de 7 testes em `processing-status.test.mjs` e ensaios A/B e F5 em Chromium.], [12/12 ações concluídas; respostas 204 e 409 tratadas resilientemente.],
    [QS-03: Resiliência a falhas], [`Tools/video/tests`], [Comportamento após interrupção forçada do worker ou restart do RabbitMQ.], [Script `run_video_recovery.py` com injeção de falhas transitórias.], [100% de lotes retomados; 0 ficheiros parciais `.part` órfãos no disco.],
    [Gestão de quotas de vídeo], [`projects/routes/projects.js`], [Reembolso incorreto de operações de vídeo ao cancelar (defeito F8).], [Testes de cancelamento concorrente e repetição de estorno em contas gratuitas.], [Estorno rigoroso de quotas confirmado para contas free e premium.],
    [Concorrência F2 e F3], [`projects/models/project.js`], [Perda de estados terminais por edição concorrente de metadados do projeto.], [3 testes em MongoDB verificando avanço independente e preservação terminal.], [Renomear projeto em execução preservou 100% dos resultados.],
  ),
) <tab-preservacao-funcional>

#tab([Riscos para a preservação funcional e mitigação],
  tabela(
    colunas: (3.2cm, 3.2cm, 4.2cm, 3.4cm),
    tamanho: 8.5pt,
    [Risco], [Funcionalidade afetada (imagem / vídeo)], [Mitigação], [Teste de regressão],
    [Condição de corrida no fecho de lote no MongoDB], [Processamento de vídeo e lotes mistos], [Registo prévio de todos os `Process` antes do despacho e barreira condicional atómica em `processBatch.js`.], [Ensaio P-02 e bateria de testes de concorrência com persistência real.],
    [Dessincronização de estado entre WebSocket e HTTP], [Acompanhamento de tarefas na UI], [Reconciliação assíncrona com monotonicidade de percentagem e precedência estrita de estados terminais.], [Suite `processing-status.test.mjs` e validação no Chromium com injeção de latência.],
    [Corrupção ou perda de dados em falhas de infraestrutura], [Trabalhador de vídeo e S3], [Confirmação manual (`basic_ack`) apenas após escrita completa e ficheiros temporários com bloqueio atómico.], [Ensaio de falha com interrupção forçada do worker e do RabbitMQ (QS-03).],
    [Regressão em ferramentas de imagem estática], [Processamento de imagens PIL e IA], [Preservação integral dos contratos AMQP e filas `<tool>_queue` sem qualquer alteração.], [Execução com sucesso de lotes só de imagem, só de vídeo e lotes mistos.],
  ),
) <tab-riscos-mitigacao>
