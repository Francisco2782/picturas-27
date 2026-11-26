#import "../template.typ": *

= Utilização de IA

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 7, e Exercício 7, secção 6.

  Obrigatório: documentar as ferramentas, os modelos e as _skills_ utilizadas, enumerar as tarefas apoiadas e comprovar a
  validação realizada pela equipa, tanto na análise e na escrita como no código e nas medições. A equipa é responsável
  por todo o conteúdo entregue, incluindo o gerado por IA.

  Valoriza-se evidência concreta (_commits_, ficheiros de configuração dos agentes) e reflexão crítica: o que a IA
  fez bem, onde errou, como o erro foi detetado e o que foi rejeitado e porquê. Não basta dizer que a IA foi usada; é preciso mostrar
  que o resultado foi verificado.
]

== Ferramentas, modelos e configuração

#tabela(
  colunas: (3.5cm, 1fr),
  [Ferramenta / modelo], [Configuração e utilização (_skills_, instruções de projeto, MCP, …)],
  [Gemini e Claude Code], [Os exercícios registam apoio ao diagnóstico e à formulação das táticas. O exercício 7 regista Gemini 3.8 Flash. A versão do modelo usado através de Claude Code fica por confirmar.],
  [Codex (GPT-6)], [Retoma do D-01 e redação do D-02 com as instruções de `AGENTS.md`. Nesta etapa, leu o repositório, executou as verificações locais e usou a skill PDF para conferir a renderização do rascunho.],
)

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas por IA e validação],
  tabela(
    colunas: (2.6cm, 2.4cm, 2.4cm, 2.8cm, 2.8cm),
    tamanho: 8.5pt,
    [Ferramenta / modelo / _skill_], [Tarefa apoiada (capítulo)], [O que foi aceite], [O que foi rejeitado e porquê], [Como foi validado pela equipa],
    [Gemini e Claude Code], [Análise estática e classificação das táticas], [Referências de código, TAT-01 a TAT-06 e classes A/B.], [Filas dedicadas e mudanças de formato das mensagens foram excluídas por excederem o âmbito.], [Os exercícios registam inspeção do código e consulta das referências da unidade curricular.],
    [Codex], [Inventário, recontagem e preparação dos capítulos finais], [Arquivo D-01 e rascunho das medições, regressões e limitações.], [A primeira recontagem de operabilidade tratava como lista um contador inteiro. A execução local detetou o erro e a correção foi verificada após extração.], [A conferência automática local passou. A revisão humana e a reprodução por outro membro estão pendentes.],
    [Codex (GPT-6 Luna)], [Auditoria documental, alinhamento dos resultados do relatório e referências dos exercícios.], [Prazo indicado pela equipa, distinção das campanhas, instruções de recontagem, referências corrigidas e verificador de citações.], [Não foi inventada uma fundamentação para os limiares nem afirmada consulta do documento de arquitetura indisponível.], [O verificador de citações e três testes passaram. `git diff --check` passou. A compilação Typst não foi possível neste ambiente. A revisão humana continua pendente.],
  ),
)

== Análise crítica

Os registos de fecho distinguem ensaios válidos de tentativas incompletas. A inspeção dos logs do worker e do SeaweedFS esclareceu a falha de armazenamento na primeira campanha de capacidade. No browser, a correção do seletor de notificações e a espera pela confirmação do estado ativo permitiram verificar os casos de conflito do cancelamento. A classificação de cada execução e a evidência de regressão podem ser revistas nos registos P-02, U-04 e de fecho. O repositório contém definições de skills Spec Kit. O uso por tarefa nas sessões anteriores e a revisão humana final ficam por confirmar com a equipa.

Na auditoria documental de 26/11, Codex verificou os resultados arquivados, corrigiu as referências identificadas e criou um verificador para caminhos e intervalos citados. Os testes confirmaram a resolução das citações na revisão-base `0523102`. A justificação original dos limiares não estava registada, pelo que o relatório explicita essa limitação. A compilação do documento e a revisão humana continuam pendentes.

No seguimento de QS-03, Codex escreveu as provas de interrupção e do polling, reproduziu duas falhas e implementou persistência, reconexão e limpeza por saída. Os dois ensaios com falha injetada, a regressão de extração de fotogramas e as suites locais verificaram a correção. Os dados estão no registo de recuperação e polling.

Para F2 e F3, Codex escreveu três regressões em MongoDB, confirmou as falhas na revisão anterior e implementou as correções. As mesmas regressões passaram na revisão corrigida. A prova pela API confirmou os dois resultados após uma edição durante o processamento.
