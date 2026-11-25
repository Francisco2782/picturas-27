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
    colunas: (1.6cm, 2.6cm, 3cm, 2.4cm, 2.8cm, 2.6cm, 2cm, 3cm, 2.8cm),
    tamanho: 7.5pt,
    [\#], [Característica / subcaracterística (ISO/IEC 25010)], [Fragilidade na base (evidência)], [Origem (padrão global / vídeo / interação)], [Impacto nos stakeholders (pertinência)], [Exigência técnica (complexidade)], [Cenário (`QS-nn`, cap. 5)], [Escala e método de medição (esboço)], [Pré-requisitos / efeitos colaterais],
    [CAND-1], [Eficiência de desempenho, capacidade], [`EV-04`, `EV-05` e `EV-08`: uma legendagem longa ocupa o único consumidor.], [Trabalhos curtos ficam à espera.], [Utilizadores e operação], [Consumo concorrente da fila], [QS-01], [Alta, atraso comum a todos os projetos], [Selecionado],
    [CAND-2], [Usabilidade, operabilidade], [`EV-10`, `frontend/app/dashboard/[pid]/page.tsx` na baseline `0523102`: overlay bloqueante e estado volátil no browser.], [O utilizador perde acesso à edição ou ao acompanhamento.], [Utilizadores], [Estado recuperável e interface navegável], [QS-02], [Alta, afeta trabalhos longos], [Selecionado],
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
    [Escala], [Segundos até ao primeiro arranque de B a partir da submissão de B.], [Ações bem-sucedidas por ensaio, recuperações por percurso e conclusões prematuras.],
    [Cenário de medição], [QS-01, sobreposição de uma legendagem longa e um lote de brilho.], [QS-02, alternar entre A e B durante a legendagem, depois recarregar.],
    [Carga], [Um vídeo em A, três em B.], [Uma sessão premium, dois projetos, fala de 10 s em A.],
    [Ambiente], [Docker Compose e RabbitMQ, uma réplica na base e duas no final.], [Chrome a 1280 × 720, HTTPS local.],
    [Instrumento], [Runner, logs Docker, amostras RabbitMQ e Docker stats.], [Protocolo A/B e registos de browser. O driver final usa Playwright.],
    [Valor medido na base], [61,727 s em média (61,390–61,936 s).], [6/12 ações. Navegação 0/3 e recarregamento 0/3.],
    [Valor-alvo], [Média ≤ 15 s em três ensaios válidos.], [12/12 ações, navegação 3/3, recarregamento 3/3 e zero falsas conclusões.],
    [Valor mínimo aceitável], [Média ≤ 30 s em três ensaios válidos.], [Pelo menos 3/4 ações por ensaio, navegação 3/3, recarregamento 3/3 e zero falsas conclusões.],
  ),
)

== Relação entre os dois candidatos

Os limiares constam da gate B-04 de 17/11/2026. Os dois requisitos permitem trabalhar durante uma execução longa. As réplicas reduzem a espera por processamento e o snapshot mantém o acompanhamento na interface. Os ensaios medem separadamente os dois efeitos. A amostragem de recursos e de tráfego documenta os custos observáveis.

== Evidência exploratória (se existir)

#tab([Evidência exploratória],
  tabela(
    colunas: (4cm, 5cm, 1fr),
    [Descrição], [Localização (_scripts_, dados, resultados)], [Como repetir],
    [Ensaio P-01 com duas réplicas.], [`docs/fase-2-implementacao.md` e registos P-01.], [Usar o cenário de capacidade com `--expected-workers 2`.],
  ),
)
]
