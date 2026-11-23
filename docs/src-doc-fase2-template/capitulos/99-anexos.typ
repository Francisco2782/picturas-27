#import "../template.typ": *

#set heading(numbering: "A.1.")
#counter(heading).update(0)

= Instruções de execução

#orientacao[
  Indiquem os passos mínimos para lançar a solução a partir do repositório (pré-requisitos, comandos, projeto de teste) e
  para repetir as medições (antes e depois do _refactoring_) (_scripts_, dados, ambiente). Quem avalia, ou a equipa na fase seguinte, deve
  conseguir repetir o que descrevem sem ajuda. No glossário, definam os termos específicos do projeto ou da disciplina
  usados no relatório.
]

Extrair `picturas-phase2-d01.tar.gz` para um diretório vazio. O ficheiro `evaluation/phase2-reproduction.md`, incluído no arquivo, descreve a verificação SHA-256, a recontagem dos dois requisitos e a repetição dos cenários sobre o sistema. A verificação local confirmou 141 ficheiros do arquivo, três ensaios medidos em cada série de capacidade e os totais de operabilidade da base e do final. A reprodução independente está por registar.

= Glossário

#tabela(
  colunas: (4cm, 1fr),
  [Termo], [Definição],
  [QS], [Cenário de qualidade. Descreve o estímulo, o ambiente e uma resposta mensurável.],
  [DA], [Decisão arquitetural associada a um cenário.],
  [Snapshot], [Estado persistido da execução, usado para recuperar o acompanhamento.],
)
