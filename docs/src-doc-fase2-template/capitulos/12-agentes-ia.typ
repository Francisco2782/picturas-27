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

Todo o trabalho apoiado por IA decorreu com agentes a operar sobre instruções versionadas no próprio repositório. O ficheiro `AGENTS.md` na raiz funciona como configuração persistente dos agentes: fixa as convenções de código, os pontos frágeis conhecidos, a obrigação de documentar cada tarefa e os critérios de revisão. Qualquer sessão de agente começa assim pelas mesmas restrições que a equipa usa para a avaliar.

A técnica central de contexto e rastreabilidade foi o registo de sessão: cada tarefa que altera o repositório mantém um registo em `docs/sessoes/AAAA-MM-DD-<tarefa>.md` escrito à medida que o trabalho avança, com as decisões e a sua justificação, os comandos realmente executados e os seus resultados, e os itens pendentes com os comandos para os reproduzir. Por estes registos viverem no repositório, cada sessão seguinte de agente (e cada membro da equipa) parte deles como fonte de verdade.

O método de trabalho seguiu três regras. Primeira, cada tarefa tem autorização humana prévia e o resultado é revisto antes de avançar, as alterações entram em _commits_ pequenos com assunto descritivo, o que permite auditar cada dif. Segunda, uma afirmação só entra no relatório com o comando que a suporta executado e o resultado registado, o que não foi verificado fica marcado como pendente em vez de afirmado. Terceira, correções a textos gerados por IA em sessões anteriores só se aplicam após autorização explícita do utilizador, ficando a decisão registada na sessão.

== Ferramentas, modelos e configuração

#tabela(
  colunas: (3.2cm, 2.6cm, 1fr, 3.6cm),
  [Ferramenta / modelo], [Etapa], [Utilização registada], [Configuração],
  [Gemini 3.8 Flash e Claude Code], [Análise e arquitetura], [Apoio à análise estática, à identificação de evidências e à formulação de táticas e tabelas de decisão dos Exercícios 6 e 7.], [Uso conversacional, sem ficheiros de configuração versionados; ao operar sobre o repositório, o Claude Code aplica as instruções de `AGENTS.md`.],
  [Codex (GPT-6)], [Implementação e validação], [Apoio à implementação, instrumentação dos ensaios de medição, análise de regressões, auditoria de rastreabilidade e preparação e revisão da documentação técnica. Operou com as instruções de `AGENTS.md` e os registos de sessão como contexto; a análise final não substituiu a revisão humana do código ou dos resultados.], [`AGENTS.md` na raiz (convenções, pontos frágeis e critérios de revisão) e os registos de `docs/sessoes/` como contexto de cada sessão.],
  [_Skills_ e _checkers_], [Composição e verificação], [_Skill_ PDF na conferência da composição do documento. _Script_ `docs/exercicios/check_citations.py` com testes próprios, criado durante a auditoria para verificação mecânica das citações `ficheiro:linha` contra uma revisão Git.], [`check_citations.py` usa a base oficial `0523102` por omissão; testes em `docs/exercicios/tests/`.],
)

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas e verificações registadas],
  tabela(
    colunas: (3.2cm, 3.4cm, 4.2cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [Ferramenta / modelo / _skill_], [Tarefa apoiada (capítulo)], [Resultado incorporado], [Como foi validado pela equipa], [Evidência verificável],
    [Gemini 3.8 Flash / Claude Code], [Diagnóstico e táticas (capítulos 3 a 7).], [Evidências de código e alternativas para capacidade e operabilidade.], [Inspeções de código e confronto das propostas com a arquitetura real e os Exercícios 6 e 7.], [Repositório, sessões de diagnóstico e plano de decisões.],
    [Codex (GPT-6) e scripts de automação], [Medição e documentação (capítulo 10 e Anexo A).], [Instrumentos A/B, arquivo D-01 e revisão de referências.], [Recontagem após extração, verificação de checksums e execuções das suítes aplicáveis.], [Anexo A, arquivo exterior e sessão `2026-11-24-validacao-final-3cb1b74.md`.],
    [Codex (GPT-6)], [Recuperação e concorrência (capítulo 10).], [Persistência, reconexão e limpeza no worker.], [Ensaios de interrupção, regressões em MongoDB e verificação de resultados pela API.], [Registos P-02, QS-03 e `2026-11-24-reentrega-resultados.md`.],
    [Codex (GPT-6)], [Elasticidade e editor (capítulo 10).], [Controlador, saída graciosa e correção da lista de efeitos aplicada a projetos partilhados.], [Ensaios com Docker e regressão em Chromium para dono, leitor e editor.], [Revisões `c4ddc6c`, `bb1d671`, `c2f4a3f` e o arquivo de elasticidade.],
    [Codex (GPT-6)], [Escrita e revisão do relatório (capítulos 1 a 10).], [Revisão de referências, renumeração de evidências e alinhamento dos valores com as campanhas.], [Compilação Typst e renderização com Tinymist; auditoria mecânica de citações contra a base `0523102`.], [Sessões `2026-11-25-revisao-relatorio-inicial.md` e `2026-11-26-auditoria-submissao.md`.],
  ),
)

Em contrapartida ao que foi aceite, as rejeições relevantes recaíram sobre propostas da própria IA. Na formulação das táticas dos Exercícios 6 e 7, as sugestões de criar filas dedicadas por tipo de carga e de alterar o formato das mensagens entre serviços foram recusadas por acrescentarem funcionalidade nova em vez de melhorar a existente, violando a restrição de _refactoring_ puro da fase. No capítulo 10, a equipa recusou o critério do instrumento de medição que tratava como válidos ensaios com erros de amostragem. E o texto do relatório foi repetidamente devolvido: sobreafirmações como «reprodutibilidade integral» e a descrição de resultados como atómicos foram retiradas ou reduzidas porque excediam a evidência executada, num controlo feito pela auditoria mecânica contra a base `0523102` e pela conferência com `git show`. Em todos os casos, a rejeição partiu da confrontação com um critério explícito, como a restrição da fase, o protocolo de medição, a evidência, e não de uma apreciação de estilo.

== Análise crítica

Olhando para a fase no seu conjunto, a IA foi mais fiável onde o critério de sucesso era verificável por execução. A instrumentação dos ensaios A/B, a derivação do indicador de espera de B, os testes de regressão de estado do cliente e a auditoria de citações são tarefas em que a resposta certa se confirma ou refuta com um comando, e foi aí que o apoio da IA rendeu mais. A disciplina de registar cada comando e resultado nas sessões, por sua vez, mostrou-se o que permitiu retomar e auditar o trabalho entre sessões sem depender da memória da conversação.

Os erros concentraram-se exatamente no sítio oposto: onde a plausibilidade pode substituir-se à verdade. As citações de código que a IA escreveu pareciam corretas, isto é tinham ficheiro, linhas e uma descrição coerente, mas a auditoria mecânica contra a base `0523102` mostrou que várias não resistiam: a linha do _upload_ apontava para o fluxo de processamento, uma referência a `processBatch.js` excedia o próprio ficheiro e a linha do _ack_ indicava o ramo de mensagens inválidas. O mesmo sucedeu no texto, com afirmações como «reprodutibilidade integral» que descreviam mais do que a evidência suportava, e nos instrumentos, com o aquecimento da elasticidade a ler o campo antigo `id` dos eventos Docker e a recontagem de operabilidade a ler um contador como se fosse uma lista. O padrão é consistente: a IA produz detalhe verosímil com a mesma facilidade com que produz detalhe correto, e a diferença só se revela executando. Estes erros foram apanhados pela conferência com `git show`, pela validação do instrumento, pela recontagem independente e os resultados inválidos ficaram conservados nos arquivos como corrigidos em vez de descartados, para que a correção do método ficasse documentada.

Esta experiência moldou o método mais do que qualquer acerto. Foi a sequência de erros detetados que levou à criação do `check_citations.py`, à regra de só entrar no relatório o que tem comando executado por trás, e à regra de marcar como pendente o que não foi verificado em vez de o afirmar de forma mais suave. No sentido oposto, o comportamento que a equipa quis incentivar também ocorreu: perante decisões que não registavam a justificação original dos limiares, a IA assinalou a lacuna em vez de atribuir à equipa uma fundamentação que não existia e foi mantido assim porque descreve o estado real e deixa a confirmação ao leitor.

A avaliação honesta fica, por isso, em dois planos. No técnico, os resultados apresentados no capítulo 10 foram produzidos e verificados com apoio de IA, mas nenhuma medição foi alterada para caber num alvo, e as correções de erros do próprio instrumento ficaram registadas. No do juízo, a IA apoiou a formulação das alternativas e a deteção de inconsistências, mas as decisões arquiteturais, a escolha dos alvos e a interpretação dos _trade-offs_ foram, e continuam a ser, da equipa.


=== Responsabilidade e aprovação da equipa
A responsabilidade pelo conteúdo entregue é da equipa, incluindo todo o texto, o código e as medições gerados com apoio de IA: as ferramentas atuaram sob direção humana e nenhum resultado passou para o relatório sem a validação descrita nas secções anteriores. 
