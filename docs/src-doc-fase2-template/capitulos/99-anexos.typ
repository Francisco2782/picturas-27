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

Para recontar os resultados, obter `picturas-phase2-final-3cb1b74.tar.gz` e o respetivo ficheiro `.sha256` junto da equipa. Confirmar o checksum exterior, extrair o arquivo para um diretório vazio, validar `SHA256SUMS` e executar `verify_final.py` dentro de `phase2-final-3cb1b74`. O script reconta os ensaios arquivados e confirma 0,123429 s de espera média de B, 12/12 ações e 3/3 recuperações por navegação, recarga e reconexão. Isto reconta registos existentes, não repete a campanha sobre o sistema. Para repetir os cenários ao vivo, seguir `evaluation/phase2-reproduction.md`, incluído no arquivo. A reprodução independente está por registar.

= Glossário

#tabela(
  colunas: (4cm, 1fr),
  [Termo], [Definição],
  [QS], [Cenário de qualidade. Descreve o estímulo, o ambiente e uma resposta mensurável.],
  [DA], [Decisão arquitetural associada a um cenário.],
  [Snapshot], [Estado persistido da execução, usado para recuperar o acompanhamento.],
)
