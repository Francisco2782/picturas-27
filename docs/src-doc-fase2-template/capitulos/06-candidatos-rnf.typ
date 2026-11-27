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

#tab([Candidatos a requisitos não funcionais da Fase 2],
  tabela(
    colunas: (1.5cm, 2.6cm, 3cm, 2.5cm, 2.6cm, 2.5cm, 1.7cm, 3.1cm, 2.7cm),
    tamanho: 7.5pt,
    [\#], [Característica / subcaracterística (ISO/IEC 25010)], [Fragilidade na base (evidência)], [Origem (padrão global / vídeo / interação)], [Impacto nos stakeholders (pertinência)], [Exigência técnica (complexidade)], [Cenário (`QS-nn`, cap. 5)], [Escala e método de medição (esboço)], [Pré-requisitos / efeitos colaterais],
    [CAND-1], [Eficiência de desempenho, capacidade], [`EV-04`, `EV-05` e `EV-08`: uma legendagem longa ocupa o único consumidor (`prefetch_count=1`).], [Padrão do vídeo (consumidor único em `video_queue`).], [Alto: trabalhos curtos de outros utilizadores ficam bloqueados em fila.], [Média: escala de réplicas no Compose e proteção de fecho concorrente (`H-01`).], [QS-01], [Segundos de espera até ao arranque de B no ensaio A/B (`evaluation/run_scenario.py`).], [Exige proteção de corrida no fecho do lote e aumenta o pico de RAM.],
    [CAND-2], [Usabilidade, operabilidade], [`EV-10` (`frontend/app/dashboard/[pid]/page.tsx` na baseline `0523102`): _overlay_ bloqueante e estado volátil no browser.], [Interação entre orquestrador e interface cliente.], [Alto: o utilizador perde acesso à edição e o acompanhamento em tarefas longas.], [Média a alta: persistência atómica no MongoDB, rota de estado e reconciliação na UI.], [QS-02], [Ações A/B (0–12), recuperações por percurso (0–3) e falsas conclusões.], [Depende da persistência prévia no backend e acrescenta consultas HTTP de estado.],
  ),
)

== Quantificação

#orientacao[
  Indiquem a *escala* (o que se mede e em que unidade) e o *método de medição* (cenário, carga, ambiente e instrumento) de
  cada candidato. O objetivo é mostrar que o requisito é mensurável e que sabem como o medir.

  Os valores medidos na base, os valores-alvo e os valores mínimos aceitáveis *só são fixados após a medição inicial
  (_baseline_, capítulo 10)*. Não os inventem: preencham as três últimas linhas da tabela só depois de medir a base,
  indicando a origem de cada valor (e.g., medição, referência externa, necessidade de um _stakeholder_).
]

#tab([Quantificação dos requisitos não funcionais],
  tabela(
    colunas: (4.2cm, 1fr, 1fr),
    [], [CAND-1], [CAND-2],
    [Escala], [Segundos até ao primeiro arranque de B a partir da submissão de B (`b_wait_seconds`).], [Ações bem-sucedidas por ensaio, recuperações por percurso e conclusões prematuras.],
    [Cenário de medição], [QS-01, sobreposição de uma legendagem longa (A) e um lote de brilho (B).], [QS-02, alternar entre A e B durante a legendagem, depois recarregar e reconectar.],
    [Carga], [Um vídeo longo em A, três vídeos curtos em B.], [Uma sessão premium, dois projetos, fala de 10 s em A.],
    [Ambiente], [Docker Compose e RabbitMQ, uma réplica na base e duas no final.], [Chromium a 1280 × 720, HTTPS local.],
    [Instrumento], [Runner (`evaluation/run_scenario.py`), logs Docker, amostras RabbitMQ e Docker stats.], [Protocolo A/B e registos de browser (`browser_u04.py` com Playwright no final).],
    [Valor medido na base], [61,727 s em média (61,390–61,936 s).], [6/12 ações. Navegação 0/3 e recarregamento 0/3.],
    [Valor-alvo], [Média ≤ 15 s em três ensaios válidos.], [12/12 ações, navegação 3/3, recarregamento 3/3 e zero falsas conclusões.],
    [Valor mínimo aceitável], [Média ≤ 30 s em três ensaios válidos.], [Pelo menos 3/4 ações por ensaio, navegação 3/3, recarregamento 3/3 e zero falsas conclusões.],
  ),
)

== Relação entre os dois candidatos

Os dois candidatos são independentes: nenhum é condição do outro, pois `CAND-2` só pressupõe estado persistido no backend, e continua a ser necessário mesmo com `CAND-1` implementado, já que os tempos de processamento não desaparecem. Assim, os dois requisitos atuam de forma complementar para permitir trabalhar durante uma execução longa: `CAND-1` reduz o tempo bloqueado na fila por contenção de recursos, enquanto `CAND-2` elimina o bloqueio na interface e preserva o acompanhamento através de estado persistido. Podem, no entanto, degradar-se mutuamente: as réplicas de `CAND-1` aumentam o pico de RAM e a concorrência sobre o RabbitMQ e o MongoDB, enquanto as consultas de estado de `CAND-2` acrescentam tráfego HTTP ao orquestrador. Os ensaios medem separadamente os dois efeitos, e a amostragem de recursos e de tráfego documenta os respetivos custos observáveis. Os limiares constam da _gate_ B-04 de 17/11/2026, fixados antes da implementação. Outros RNF afetados são a _fiabilidade_ (proteção de fecho concorrente, `H-01`, e recuperação dos consumidores) e a _eficiência_, pela carga extra em memória e rede, monitorizada nas amostras dos ensaios.

 


== Evidência exploratória (se existir)

#tab([Evidência exploratória],
  tabela(
    colunas: (4cm, 5cm, 1fr),
    [Descrição], [Localização (_scripts_, dados, resultados)], [Como repetir],
    [Ensaio P-01 com duas réplicas.], [`docs/fase-2-implementacao.md` e registos P-01.], [Usar o cenário de capacidade com `--expected-workers 2`.],
  ),
)
]
