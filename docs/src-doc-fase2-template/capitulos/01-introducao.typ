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
#preencher[Que RNF se pretende melhorar, em que parte da solução (extensão de vídeo, enquadrada no padrão global) e com que restrições (_refactoring_ que preserva o comportamento funcional).]

O presente relatório documenta o trabalho desenvolvido na Fase 2 da unidade curricular de Requisitos e Arquiteturas de Software, centrado na melhoria orientada de Requisitos Não Funcionais (RNF) do sistema PictuRAS. Partindo da solução integrada herdada da Fase 1 (desenvolvida pelo grupo PL1-G4), o objetivo fulcral consiste em diagnosticar, intervir e quantificar empiricamente a melhoria de atributos de qualidade sobre o subsistema de processamento de vídeo, enquadrado no padrão arquitetural global da plataforma.

A intervenção rege-se estritamente pelo princípio de _refactoring_ arquitetural: otimizar a estrutura interna e a eficiência operacional do sistema sem introduzir novas funcionalidades ao utilizador e preservando integralmente o comportamento funcional preexistente (pipelines de edição, formatos suportados, integridade de codecs e regras de autorização). Foram selecionados dois requisitos não funcionais prioritários:



1. *Eficiência de Desempenho — Capacidade*: mitigar o estrangulamento severo provocado pelo processamento serializado e síncrono de vídeo (`video_queue`), no qual tarefas computacionalmente intensivas executadas em CPU (nomeadamente a legendagem automática com Faster-Whisper) bloqueiam o avanço de pedidos concorrentes;

2. NOTA: Falta preencher


== _Baseline_ e repositório

O ponto de partida do sistema assenta na versão oficial disponibilizada no repositório GitHub do projeto, marcada com a _tag_ `phase2-base`. Todas as medições de referência (_baseline_) foram recolhidas nesse estado inicial sem modificações aplicacionais, garantindo que os resultados finais obtidos traduzem exclusivamente o impacto das decisões arquiteturais adotadas.

#tab([Artefactos de partida],
  tabela(
    colunas: (5.5cm, 1fr),
    [Artefacto], [Versão / referência],
    [Documento de requisitos de base], [doc-ext-requisitos-2627.pdf (Extensão de Requisitos PL1-G4)],
    [Documento de solução arquitetural de base], [doc-sol-arquitetural.pdf],
    [Repositório de partida], [https://github.com/picturas-um/picturas-27 · tag `phase2-base` (`0523102`), checkout de medição `afb84e5`],
    [Repositório entregue], [#preencher[URL e _commit_ da entrega]],
    [Diretrizes da Fase 2], [Versão 1 ],
  ),
)

== Exercícios e versões usadas

#orientacao[
  Indiquem, para cada exercício, a versão do enunciado e do _template_ que usaram, e a versão do vosso documento que
  serviu de entrada ao exercício seguinte (Bloco 1 → Bloco 2 → Exercício 7). Isto garante que quem avalia consegue
  perceber a que regras o trabalho respondeu, caso os enunciados tenham sido atualizados durante a fase.
]

#tab([Exercícios que alimentam este relatório],
  tabela(
    colunas: (3.8cm, 2.2cm, 2cm, 2cm, 1fr),
    [Exercício], [Capítulos], [Enunciado], [Template], [Versão do documento da equipa],
    [Exercício 6, Bloco 1: padrões arquiteturais], [2, 3 e 4], [1.1], [1.1], [v1.0],
    [Exercício 6, Bloco 2: trade-offs, cenários e candidatos a RNF], [5 e 6], [1.1], [1.1], [v1.0],
    [Exercício 7: táticas arquiteturais], [7 a 10], [3.0], [3.0], [v1.0],
  ),
)

== Organização do documento
#preencher[Resumo, em poucas linhas, do que contém cada Parte e de como os IDs encadeiam os capítulos (`EV`/`H` → `ALT` → `QS`/`CAND` → `TAT` → `DA`).]

NOTA: REVER ISTO NO FIM


O relatório encontra-se estruturado em cinco partes que refletem o ciclo metodológico completo _Diagnóstico → Decisão → Implementação → Avaliação_:

- *Parte I — Enquadramento e Metodologia* (Capítulo 1): contextualização do propósito, restrições de _refactoring_, identificação da _baseline_ oficial e versão dos artefactos de partida.
- *Parte II — Diagnóstico Arquitetural* (Capítulos 2, 3 e 4, alimentados pelo Exercício 6, Bloco 1): análise do âmbito global da solução e caracterização da bifurcação entre imagem e vídeo, identificação dos estilos arquiteturais atuais (_Microserviços Orientados a Eventos_ global vs. _Pipeline Monolith_ no vídeo) e confronto com padrões alternativos (`ALT-1` a `ALT-3`), com recurso a evidências no código (`EV-01` a `EV-10`) e formulação de hipóteses (`H-01` a `H-03`).
- *Parte III — Requisitos de Qualidade e Diagnóstico Detalhado* (Capítulos 5 e 6, alimentados pelo Exercício 6, Bloco 2): aprofundamento das justificações da matriz de _trade-offs_, caracterização formal dos cenários de qualidade (`QS-01` a `QS-03`) com os seis elementos prescritos na literatura e seleção dos dois candidatos a RNF (`CAND-1` e `CAND-2`), estabelecendo as escalas e os métodos de quantificação empírica.
- *Parte IV — Táticas, Decisões e Avaliação Experimental* (Capítulos 7 a 10, alimentados pelo Exercício 7): identificação de táticas candidatas (`TAT-01` a `TAT-06`), formalização das decisões arquiteturais (`DA-1` e `DA-2`), vista arquitetural comparativa Antes/Depois, avaliação de impactos cruzados e plano de medição e de testes de regressão funcional.
- *Parte V — Síntese, Conclusões e Transparência* (Capítulos 11 e 12): síntese conclusiva sobre a adequação dos padrões, balanço de trade-offs observados, recomendações para evolução futura e registo transparente das ferramentas de Inteligência Artificial utilizadas no apoio às tarefas.

O encadeamento conceptual ao longo de todo o documento assenta na estabilidade dos identificadores: as evidências e hipóteses (`EV`/`H`) fundamentam a análise de alternativas (`ALT`) e os cenários de qualidade (`QS`/`CAND`), que por sua vez motivam as táticas (`TAT`) consolidadas nas decisões arquiteturais (`DA`), garantindo rastreabilidade contínua de ponta a ponta.
