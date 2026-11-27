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
  colunas: (3.5cm, 1fr),
  [Ferramenta], [Utilização registada],
  [Gemini e Claude Code], [Apoio à análise estática, à identificação de evidências e à formulação de táticas. O Exercício 7 identifica o modelo Gemini 3.8 Flash.],
  [Codex (GPT-6)], [Apoio à implementação, instrumentação dos ensaios, análise de regressões e preparação e revisão da documentação técnica. Foram usadas as instruções do repositório em `AGENTS.md` e a _skill_ PDF na conferência da composição do documento.],
)

== Verificação dos contributos

#tab([Tarefas apoiadas e verificações registadas],
  tabela(
    colunas: (3.4cm, 1fr, 1fr),
    tamanho: 8.5pt,
    [Área], [Resultado incorporado], [Verificação registada],
    [Diagnóstico e táticas], [Evidências de código e alternativas para capacidade e operabilidade.], [Inspeções de código e consulta de fontes registadas nos Exercícios 6 e 7.],
    [Medição e documentação], [Instrumentos A/B, arquivo D-01 e revisão de referências.], [Recontagem após extração, verificação de checksums e conferência de citações na revisão `0523102`.],
    [Recuperação e concorrência], [Persistência, reconexão e limpeza no worker.], [Ensaios de interrupção, regressões em MongoDB e verificação de resultados pela API.],
    [Elasticidade e editor], [Controlador, saída graciosa e correção da lista de efeitos aplicada a projetos partilhados.], [Ensaios com Docker e regressão em Chromium para dono, leitor e editor. Revisões `c4ddc6c`, `bb1d671` e `c2f4a3f`.],
  ),
)

== Análise crítica

A separação de filas por tipo de carga foi rejeitada pelo custo de alterar o encaminhamento e os contratos existentes. Durante a validação, a execução do verificador detetou que a primeira recontagem de operabilidade interpretava um contador como lista. No ensaio de elasticidade, o primeiro aquecimento expôs a leitura incorreta do identificador do contentor nos eventos Docker. O arquivo conserva essa execução inválida e os resultados obtidos após a correção do instrumento.

A validação técnica apresentada reúne inspeções, testes executados e medições instrumentadas. Os registos P-02, U-04, de recuperação, de elasticidade e de acesso em modo de leitura documentam as verificações. A composição do relatório foi conferida por compilação e renderização com Tinymist.
