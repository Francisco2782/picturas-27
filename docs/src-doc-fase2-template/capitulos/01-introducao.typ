#import "../template.typ": *

= Introdução

#orientacao[
  Uma a duas páginas, no máximo. O leitor deve perceber, sem ler o resto, o que é este documento e em que se baseia.
  Respondam a:
  - *Propósito da fase*: que requisitos não funcionais do PictuRAS se pretende melhorar, por _refactoring_ e sem novas
    funcionalidades, e porquê.
  - *_Baseline_*: em que versão do sistema se basearam (_commit_ de partida), a mesma em todos os exercícios. Este
    relatório *estende* os documentos de base; não os reescreve.
  - *Âmbito do que é apresentado*: este relatório reúne os contributos dos Exercícios 6 (Blocos 1 e 2) e 7. Reutiliza
    os respetivos _templates_: copiem o conteúdo já preenchido, *mantendo os IDs* (`EV`, `H`, `ALT`, `QS`, `CAND`,
    `TAT`, `DA`), porque é através deles que os capítulos se encadeiam.
  - *Organização do documento*: Partes II (diagnóstico), III (qualidade), IV (táticas, decisões, medição e resultados)
    e V (síntese).
]

== Propósito e âmbito

O presente relatório documenta o trabalho desenvolvido na Fase 2 da unidade curricular de Requisitos e Arquiteturas de Software. O foco desta fase consiste na melhoria orientada de Requisitos Não Funcionais (RNF) sobre a plataforma *PictuRAS* através de _refactoring_ arquitetural, respeitando a restrição fundamental de não introduzir novas funcionalidades visíveis ao utilizador final.

A aplicação PictuRAS constitui uma solução web de edição em lote de imagens e vídeos estruturada em microsserviços sobre Docker Compose. O utilizador cria projetos, carrega múltiplos ficheiros multimédia e define uma sequência ordenada de transformações (_pipeline_), a qual é aplicada em lote a todos os elementos do projeto. Na Fase 1, o sistema foi estendido para suportar processamento de vídeo numa lógica de Produto Mínimo Viável (MVP), comprovando a viabilidade funcional mas herdando limitações críticas de qualidade de serviço sob carga e na experiência de utilização.

A partir do diagnóstico das fragilidades da solução de base oficial herdada (desenvolvida pelo grupo PL1-G4), foram selecionados dois Requisitos Não Funcionais distintos e complementares:

1. *Eficiência de Desempenho — Capacidade*: o subsistema de vídeo original executa um único consumidor na fila RabbitMQ (`video_queue`), com receção unitária (`prefetch_count=1`). Tarefas de elevado custo computacional em CPU, em particular a legendagem automática, provocam um estrangulamento severo por bloqueio de cabeça de fila (_Head-of-Line Blocking_), fazendo com que pedidos de vídeo curtos e leves aguardem mais de um minuto para iniciar o seu processamento. O objetivo foi viabilizar o processamento concorrente através de réplicas de trabalhadores sob a mesma fila, mitigando drasticamente o tempo de espera.
2. *Usabilidade — Operabilidade*: durante a execução de um lote de vídeo, a interface cliente original sobrepunha uma janela modal obstrutiva (_overlay_) que bloqueava totalmente a navegação da aplicação. Adicionalmente, o estado e a percentagem de progresso residiam exclusivamente na memória volátil do componente React: qualquer navegação entre páginas ou recarregamento de página (_refresh_ F5) destruía a visibilidade da execução, impossibilitando o acompanhamento e o controlo do projeto. O objetivo consistiu em persistir atomicamente o estado de execução no backend, eliminar o bloqueio de ecrã e disponibilizar um painel desacoplado no layout global da aplicação web.

== _Baseline_ e repositório

O desenvolvimento partiu da versão oficial disponibilizada no repositório GitHub do projeto (`picturas-um/picturas-27`), com a _tag_ `phase2-base`. A caracterização empírica inicial foi estabelecida através de medições instrumentadas sobre a solução original antes de qualquer intervenção no código.

#tab([Artefactos de partida],
  tabela(
    colunas: (5.5cm, 1fr),
    [Artefacto], [Versão / referência],
    [Documento de requisitos de base], [doc-ext-requisitos-2627.pdf (Extensão de Requisitos PL1-G4, Fase 1)],
    [Documento de solução arquitetural de base], [doc-sol-arquitetural.pdf],
    [Repositório de partida], [https://github.com/picturas-um/picturas-27 · tag `phase2-base` (`0523102`), checkout de medição `afb84e5`],
    [Repositório entregue], [https://github.com/Francisco2782/picturas-27 · branch `main`],
    [Diretrizes da Fase 2], [fase-2-guidelines.pdf (Versão 1)],
  ),
)

== Exercícios e versões usadas

#orientacao[
  Indiquem, para cada exercício, a versão do enunciado e do _template_ que usaram, e a versão do vosso documento que
  serviu de entrada ao exercício seguinte (Bloco 1 → Bloco 2 → Exercício 7). Isto garante que quem avalia consegue
  perceber a que regras o trabalho respondeu, caso os enunciados tenham sido atualizados durante a fase.
]

O relatório integra, consolida e aprofunda os trabalhos produzidos ao longo dos blocos de exercícios práticos, cujas versões de referência se encontram registadas na @tab-exercicios-base.

#tab([Exercícios que alimentam este relatório],
  tabela(
    colunas: (4.2cm, 2.2cm, 2cm, 2cm, 1fr),
    [Exercício], [Capítulos], [Enunciado], [Template], [Versão do documento da equipa],
    [Exercício 6, Bloco 1: padrões arquiteturais], [2, 3 e 4], [1.1], [1.1], [v1.0],
    [Exercício 6, Bloco 2: trade-offs, cenários e candidatos a RNF], [5 e 6], [1.1], [1.1], [v1.0],
    [Exercício 7: táticas arquiteturais], [7 a 10], [3.0], [3.0], [v1.0],
  ),
) <tab-exercicios-base>

== Organização do documento

O documento encontra-se estruturado em cinco partes fundamentais, refletindo o ciclo metodológico completo _Diagnóstico $->$ Decisão $->$ Implementação $->$ Avaliação_:

- *Parte I — Enquadramento e Metodologia* (Capítulo 1): formulação do problema, restrições da fase de _refactoring_, caracterização dos artefactos herdados e taxonomia de rastreabilidade.
- *Parte II — Diagnóstico Arquitetural* (Capítulos 2, 3 e 4): vista global da arquitetura, identificação da bifurcação operacional entre imagem e vídeo, análise detalhada dos estilos arquiteturais em confronto (_Microsserviços Orientados a Eventos_ vs. _Pipeline Monolith_ no vídeo) e avaliação comparativa de padrões alternativos (`ALT-1` a `ALT-3`), com suporte em evidências no código (`EV-01` a `EV-10`) e formulação de hipóteses (`H-01` a `H-04`).
- *Parte III — Requisitos de Qualidade e Diagnóstico Detalhado* (Capítulos 5 e 6): caracterização rigorosa dos cenários de qualidade (`QS-01` a `QS-03`) com os seis elementos prescritos pela engenharia de software, priorização baseada no impacto para os _stakeholders_ e risco técnico, e formalização dos candidatos a RNF (`CAND-1` e `CAND-2`) com os respetivos métodos e escalas de quantificação.
- *Parte IV — Táticas, Decisões e Avaliação Experimental* (Capítulos 7 a 10): identificação de táticas candidatas (`TAT-01` a `TAT-06`), formalização das decisões arquiteturais (`DA-1` e `DA-2`) no modelo ADR, vistas antes e depois, análise de _trade-offs_ e apresentação detalhada dos resultados das medições e dos testes de preservação funcional.
- *Parte V — Síntese, Conclusões e Transparência* (Capítulos 11 e 12): síntese reflexiva sobre a adequação dos padrões, recomendações práticas para evolução do sistema e registo pormenorizado do recurso a ferramentas de Inteligência Artificial.

A coerência do relatório assenta na preservação estrita de identificadores ao longo de todo o texto: cada constatação factual sustenta-se numa evidência auditada (`EV`), as opções arquiteturais são contrapostas como alternativas (`ALT`), as fragilidades originam cenários formais (`QS`) e requisitos quantificáveis (`CAND`), que determinam a seleção de táticas (`TAT`) consolidadas em decisões arquiteturais (`DA`), posteriormente comprovadas em testes e medições de desempenho (`M`) e preservação funcional (`R`, `P`, `U`).
