#import "../template.typ": *

// Capítulo inteiro na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Candidatos a Requisitos Não Funcionais

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 5 do _template_.

  *Objetivo do capítulo:* escolher *dois* requisitos não funcionais *distintos* a melhorar nesta fase, a partir dos
  cenários de qualidade mais prioritários do capítulo 5. Cada um é classificado segundo a ISO/IEC 25010 (característica e,
  quando aplicável, subcaracterística) e parte de uma fragilidade concreta da solução de base, com evidência.

  Cada candidato é depois especificado, implementado e avaliado por si, ainda que os dois possam estar relacionados.
  A coluna do cenário liga o candidato ao `QS-nn` do capítulo 5, que é a entrada do Exercício 7 (capítulo 7).
]

A partir da priorização dos cenários de qualidade e da análise de impacto nas partes interessadas, foram formalizados dois candidatos a Requisitos Não Funcionais (RNF) distintos e rigorosamente quantificáveis, apresentados na @tab-candidatos-rnf.

#tab([Candidatos a requisitos não funcionais da Fase 2],
  tabela(
    colunas: (1.6cm, 3.2cm, 3.6cm, 2.6cm, 3.2cm, 2.8cm, 1.8cm, 3.2cm, 2.8cm),
    tamanho: 7.5pt,
    [\#], [Característica / subcaracterística (ISO/IEC 25010)], [Fragilidade na base (evidência)], [Origem (padrão global / vídeo / interação)], [Impacto nos stakeholders (pertinência)], [Exigência técnica (complexidade)], [Cenário (`QS-nn`, cap. 5)], [Escala e método de medição (esboço)], [Pré-requisitos / efeitos colaterais],
    [CAND-1], [Eficiência de desempenho: capacidade (4.2.3)], [Consumidor único com prefetch unitário (`EV-02`, `EV-03`, `EV-06`). Legendagem de 177 s atrasou o lote seguinte em mais de 60 s.], [Padrão do vídeo (processamento monolítico com trabalhador único)], [#strong[Crítico]: utilizadores com tarefas rápidas ficam bloqueados em fila por execuções longas de terceiros.], [#strong[Média]: escalamento em Docker Compose, proteção de commits de lote concorrentes em `projects`.], [QS-01], [Segundos de espera (`b_wait_seconds`) no cenário A/B com harness automatizado (`evaluation/run_scenario.py`).], [Exige proteção contra perda de dados em fechos simultâneos (P-02); acarreta aumento de consumo de RAM.],
    [CAND-2], [Usabilidade: operabilidade (4.3.4)], [Janela modal sobreposta bloqueia toda a UI; estado e progresso residem apenas na memória volátil do React (`EV-08`).], [Interação (orquestrador backend $arrow.l.r$ frontend SPA)], [#strong[Elevado]: utilizador impossibilitado de navegar ou trabalhar durante lotes e perde a visibilidade se fizer reload.], [#strong[Média a Alta]: persistência atómica no MongoDB, endpoint seguro e reconciliação cliente-servidor.], [QS-02], [Ações bem-sucedidas em concorrência (0-12) e taxa de recuperação após navegação e refresh (0-3).], [Depende de persistência atómica de snapshots (`EV-04`); adiciona tráfego HTTP periódico de polling.],
  ),
) <tab-candidatos-rnf>

== Quantificação

#orientacao[
  Indiquem a *escala* (o que se mede e em que unidade) e o *método de medição* (cenário, carga, ambiente e instrumento) de
  cada candidato. O objetivo é mostrar que o requisito é mensurável e que sabem como o medir.

  Os valores medidos na base, os valores-alvo e os valores mínimos aceitáveis *só são fixados após a medição inicial
  (_baseline_, capítulo 10)*. Não os inventem: preencham as três últimas linhas da tabela só depois de medir a base,
  indicando a origem de cada valor (e.g., medição, referência externa, necessidade de um _stakeholder_).
]

A especificação quantitativa de cada candidato estabelece a escala de medida, o cenário de teste, o perfil de carga, o ambiente de execução e a instrumentação utilizada. Os valores da linha de base (*baseline*) oficial foram obtidos antes de qualquer alteração de código, servindo de critério empírico para a fixação dos valores-alvo e mínimos aceitáveis, detalhados na @tab-quantificacao-rnf.

#tab([Quantificação dos requisitos não funcionais],
  tabela(
    colunas: (4.4cm, 1fr, 1fr),
    tamanho: 8.5pt,
    [], [CAND-1 (Eficiência de Desempenho — Capacidade)], [CAND-2 (Usabilidade — Operabilidade)],
    [Escala (o que se mede e em que unidade)], [Tempo de espera `b_wait_seconds` (em segundos): intervalo decorrido entre a submissão HTTP do lote B e o primeiro registo de execução de brilho no trabalhador `video_tool`.], [Contagem de ações bem-sucedidas durante o lote ativo (0-4 por ensaio, total 0-12 em 3 ensaios) e taxa de recuperação do estado e progresso após navegação (0-3) e após recarregamento (0-3).],
    [Cenário de medição], [Cenário automatizado A/B: Projeto A executa legendagem de vídeo com fala de 177 s. Projeto B é submetido 1 a 2 s depois com três vídeos (dois MP4 de 10 s e um MOV de 6 s com brilho).], [Cenário de utilizador no navegador: Projeto A inicia legendagem em vídeo de 10 s. Durante a execução, o utilizador abre o Projeto B, interage com a toolbar, regressa a A e recarrega a página (F5).],
    [Carga], [2 projetos concorrentes, totalizando 4 ficheiros de vídeo submetidos em simultâneo com filtros de IA e de cor.], [1 utilizador autenticado com perfil premium, 2 projetos alternados durante a janela de processamento ativo (~10 a 60 segundos).],
    [Ambiente], [Contentores Docker Compose no host oficial de teste, barramento RabbitMQ com filas duráveis; 1 réplica (baseline) vs 2 réplicas (final).], [Navegador Chromium versão recente, viewport fixado em 1280x720, ligação WebSocket ativa e tráfego HTTPS local (:8080).],
    [Instrumento], [Scripts `evaluation/run_scenario.py` e `evaluation/summarize.py`, logs do trabalhador e Docker stats a 1 Hz.], [Protocolo de ensaio instrumentado no Chromium (`browser_u04.py`) e registos de chamadas de rede e consola DevTools.],
    [Valor medido na base], [#strong[Média de 61,727 s] (mínimo 61,390 s, máximo 61,936 s em 3 execuções válidas seguidas).], [#strong[6/12 ações concluídas (50%)]; recuperação por navegação: #strong[0/3]; recuperação por recarregamento: #strong[0/3] (bloqueio total).],
    [Valor-alvo (e origem)], [#strong[Média final de `b_wait_seconds` $<= 15,0$ s] em três ensaios válidos.], [#strong[12/12 ações concluídas (100%)]; recuperação por navegação: #strong[3/3]; recuperação por refresh: #strong[3/3]; #strong[0 falsas conclusões].],
    [Valor mínimo aceitável (e origem)], [#strong[Média final de `b_wait_seconds` $<= 30,0$ s] em três ensaios válidos.], [#strong[$>= 3/4$ ações em cada ensaio]; recuperação por navegação: #strong[3/3]; recuperação por refresh: #strong[3/3]; #strong[0 falsas conclusões].],
  ),
) <tab-quantificacao-rnf>

== Relação entre os dois candidatos

A seleção articulada de CAND-1 e CAND-2 responde de forma integrada à experiência global do utilizador do PictuRAS perante tarefas demoradas de vídeo:
- *CAND-1* atua na dimensão do motor de computação: ao garantir que um novo trabalho não fica bloqueado na fila à espera que uma tarefa longa termine, liberta a capacidade do sistema para múltiplos utilizadores em simultâneo.
- *CAND-2* atua na dimensão da experiência e controlo: assegura que, enquanto uma tarefa demorada decorre em segundo plano, o utilizador pode continuar a usar a aplicação para outros projetos, navegar livremente e atualizar a página sem perder a perceção do estado nem o controlo sobre o cancelamento do lote.

Os dois requisitos foram medidos em ensaios separados para isolar rigorosamente as variáveis de resposta. No entanto, em termos arquiteturais, a presença de múltiplos trabalhadores sob CAND-1 alimenta eventos de progresso concorrentes para o orquestrador, reforçando a necessidade do mecanismo de snapshot atómico e validação monotónica introduzido por CAND-2.

== Evidência exploratória (se existir)

#tab([Evidência exploratória],
  tabela(
    colunas: (4cm, 5cm, 1fr),
    [Descrição], [Localização (_scripts_, dados, resultados)], [Como repetir],
    [Exploração inicial da linha de base de capacidade (bloqueio de fila)], [`evaluation/evidence/official-baseline-performance-2026-11-17`], [`PYTHONDONTWRITEBYTECODE=1 python3 evaluation/summarize.py evaluation/evidence/official-baseline-performance-2026-11-17 --runs 3`],
    [Registo exploratório do bloqueio de interface no navegador por modal sobreposto], [`docs/sessoes/2026-11-22-fecho-fase-2.md`, protocolo `browser_u04.py`], [Execução no Chromium com inspeção visual do modal `#processing-overlay` durante o lote.],
  ),
)
]
