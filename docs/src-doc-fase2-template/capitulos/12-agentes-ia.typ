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

== Ferramentas e tarefas apoiadas

#tabela(
  colunas: (3.5cm, 3.2cm, 1fr),
  [Ferramenta / modelo], [Etapa], [Utilização registada],
  [Gemini e Claude Code], [Análise e arquitetura], [Apoio à análise estática, à identificação de evidências e à formulação de táticas. O Exercício 7 identifica o modelo Gemini 3.8 Flash.],
  [Codex], [Implementação e validação], [Apoio à instrumentação dos ensaios, à análise de regressões e à preparação e revisão da documentação técnica. Foram usadas as instruções do repositório em `AGENTS.md`; a análise final não substituiu a revisão humana do código ou dos resultados.],
)

== Verificação dos contributos

#tab([Tarefas apoiadas e verificações registadas],
  tabela(
    colunas: (3.4cm, 4cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [Área], [Resultado incorporado], [Verificação registada pela equipa], [Evidência verificável],
    [Diagnóstico e táticas], [Evidências de código e alternativas para capacidade e operabilidade.], [Inspeções de código e confronto das propostas com a arquitetura real e os Exercícios 6 e 7.], [Repositório, sessões de diagnóstico e plano de decisões.],
    [Medição e documentação], [Instrumentos A/B, arquivo D-01 e revisão de referências.], [Recontagem após extração, verificação de checksums e execuções das suítes aplicáveis.], [Anexo A, arquivo exterior e sessão `2026-11-24-validacao-final-3cb1b74.md`.],
    [Recuperação e concorrência], [Persistência, reconexão e limpeza no worker.], [Ensaios de interrupção, regressões em MongoDB e verificação de resultados pela API.], [Registos P-02, QS-03 e `2026-11-24-reentrega-resultados.md`.],
    [Elasticidade e editor], [Controlador, saída graciosa e correção da lista de efeitos aplicada a projetos partilhados.], [Ensaios com Docker e regressão em Chromium para dono, leitor e editor.], [Revisões `c4ddc6c`, `bb1d671`, `c2f4a3f` e o arquivo de elasticidade.],
  ),
)

== Análise crítica

A separação de filas por tipo de carga foi rejeitada pelo custo de alterar o encaminhamento e os contratos existentes. Durante a validação, a execução do verificador detetou que a primeira recontagem de operabilidade interpretava um contador como lista. No ensaio de elasticidade, o primeiro aquecimento expôs a leitura incorreta do identificador do contentor nos eventos Docker. O arquivo conserva essa execução inválida e os resultados obtidos após a correção do instrumento.

A IA não foi usada para alterar silenciosamente os resultados das campanhas. Os instrumentos, os dados brutos e os scripts podem ser reexecutados ou verificados por checksum. Uma proposta de implementação só foi incorporada depois de inspeção humana e, quando aplicável, de passar testes unitários, integração ou ensaio no browser.

Os critérios de aceitação não dependem da interpretação de uma ferramenta de IA: QS-01 usa a espera observada até ao arranque de B, QS-02 conta ações e recuperações por ensaio e a preservação funcional exige resultado, estado e limpeza verificáveis. Os resultados deste relatório são apresentados com base nessas verificações técnicas.

A validação técnica apresentada reúne inspeções, testes executados e medições instrumentadas. Os registos P-02, U-04, de recuperação, de elasticidade e de acesso em modo de leitura documentam as verificações. A composição do relatório foi conferida por compilação e renderização com o Typst.

=== Responsabilidade e aprovação da equipa

O texto deste capítulo identifica as intervenções apoiadas por IA e a prova usada para verificar cada contribuição. Antes da submissão, a equipa deve confirmar nesta página os nomes dos membros responsáveis pela revisão humana, a data da aprovação e eventuais correções rejeitadas. Este campo faz parte da declaração de responsabilidade exigida na entrega.
