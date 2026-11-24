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

Ao longo das diversas etapas metodológicas da Fase 2, a equipa recorreu a agentes e modelos de Inteligência Artificial para acelerar o diagnóstico, apoiar a conceção arquitetural e automatizar a geração de código e de testes de validação, sob estrita supervisão e validação humana. As ferramentas e configurações utilizadas encontram-se descritas na @tab-ferramentas-ia.

#tab([Ferramentas, modelos e configuração],
  tabela(
    colunas: (3.5cm, 1fr),
    [Ferramenta / modelo], [Configuração e utilização (_skills_, instruções de projeto, MCP, …)],
    [Gemini (Gemini 3.8 Flash e Gemini Pro)], [Utilizado através da CLI do Antigravity e interface de chat com integração de _skills_ de desenvolvimento de software. Apoiou a exploração estática inicial do repositório, a catalogação de evidências e a formulação inicial dos cenários de qualidade e táticas.],
    [Claude Code], [Utilizado via terminal com acesso aos ficheiros do projeto para análise de dependências cruzadas, identificação de regras não documentadas na orquestração de vídeo e apoio à auditoria de concorrência.],
    [Codex (GPT-6)], [Executado em ambiente controlado com as instruções e convenções de `AGENTS.md`. Apoiou o empacotamento da evidência D-01, a estruturação e redação dos capítulos Typst, a criação de suites de regressão em MongoDB (sessões F2 e F3) e os testes de injeção de falhas (cenário QS-03).],
  ),
) <tab-ferramentas-ia>

== Tarefas apoiadas e validação

A atuação dos assistentes de IA foi sistematicamente enquadrada pelo princípio da validação humana integral (_Human-in-the-Loop_). Na @tab-tarefas-ia, discriminam-se as tarefas apoiadas, o que foi aceite, o que foi rejeitado com a respetiva justificação técnica e o método de validação aplicado pela equipa.

#tab([Tarefas apoiadas por IA e validação],
  tabela(
    colunas: (2.6cm, 2.4cm, 2.4cm, 3.2cm, 1fr),
    tamanho: 8pt,
    [Ferramenta / modelo / _skill_], [Tarefa apoiada (capítulo)], [O que foi aceite], [O que foi rejeitado e porquê], [Como foi validado pela equipa],
    [Gemini / Claude Code], [Diagnóstico e táticas (Caps. 2, 3 e 7)], [Mapeamento das evidências `EV-01` a `EV-10`, identificação das táticas `TAT-01` a `TAT-06` e classificação formal nas classes A/B.], [Propostas de segregação de tráfego em múltiplas filas AMQP com novos esquemas de mensagens: rejeitadas por violarem o âmbito de _refactoring_ puro (Classe C).], [Inspeção manual direta dos ficheiros de código (`video.py`, `processBatch.js`) e validação conceitual face à literatura de Bass et al.],
    [Gemini / Scripts], [Automação de testes e medição (Caps. 6 e 10)], [Geração dos scripts de orquestração do cenário A/B (`evaluation/run_scenario.py`) e cálculo da métrica `b_wait_seconds`.], [Tentativas de considerar válidas séries de medição com falhas na amostragem de Docker stats: rejeitadas com imposição de repetição de ensaios.], [Auditoria matemática das fórmulas de cálculo temporal e verificação dos ficheiros brutos de logs e estatísticas Docker.],
    [Codex], [Persistência e estado cliente (Caps. 8, 9 e 10)], [Estruturação do subdocumento `processingRun`, criação de rotas REST e suite de 7 testes em `processing-status.test.mjs`.], [Sugestão de manter o estado apenas em LocalStorage no cliente: rejeitada por não sincronizar abas e perder dados ao limpar a cache.], [Execução de `node --test` e testes instrumentados de ponta a ponta no Chromium cobrindo navegação, refresh e reconexão.],
    [Codex], [Resiliência a falhas e concorrência (Cap. 10)], [Implementação de testes de injeção de falhas para o cenário QS-03 e regressões de concorrência em MongoDB (F2 e F3).], [Proposta de ignorar a limpeza de ficheiros parciais `.part` após reinício do trabalhador: rejeitada para evitar poluição de armazenamento.], [Execução real das suites PyTest (77 testes verdes), interrupção forçada de contentores e inspeção do sistema de ficheiros.],
    [Codex], [Compilação e conferência D-01/D-02 (Caps. 1 a 12)], [Estruturação dos capítulos Typst, tabelas de dados experimentais e manifesto de empacotamento D-01.], [A primeira versão do script de verificação tratava `false_completions` como lista iterável, falhando com `TypeError`. A equipa corrigiu o tipo.], [Verificação automática de 141 hashes SHA-256 no pacote extraído e compilação limpa do documento Typst via CLI.],
  ),
) <tab-tarefas-ia>

== Análise crítica

O recurso a ferramentas de Inteligência Artificial na Fase 2 demonstrou um elevado potencial acelerador no ciclo de desenvolvimento, particularmente em tarefas de:
1. *Exploração e auditoria:* Capacidade de analisar rapidamente árvores de código complexas e isolar pontos de estrangulamento (como o `prefetch_count=1` em `video.py` ou a ausência de persistência em `dashboard/[pid]/page.tsx`);
2. *Geração de testes de fronteira:* Elaboração célere de cenários de teste automatizados em Node.js e Python, cobrindo casos de concorrência complexos (como a corrida de fecho de lote mitigada na sessão P-02);
3. *Rigor na documentação:* Estruturação de registos ADR e matrizes comparativas alinhadas com as diretrizes e normas internacionais (ISO/IEC 25010).

Em contrapartida, a experiência evidenciou riscos substanciais que exigiram vigilância humana permanente:
- *Tendência para over-engineering funcional:* Os modelos sugeriram recorrentemente a introdução de novos esquemas de filas, novos campos em mensagens públicas e persistência no cliente que ultrapassavam as fronteiras de um _refactoring_ estrito, tendo a equipa de intervir para vetar soluções de Classe C.
- *Alucinações e erros em tipos de dados:* O modelo gerou código de verificação assumindo formatos de dados incorretos (como o erro de tipo em contadores de conclusão no script de auditoria de usabilidade), demonstrando que nenhuma linha de código gerada por IA pode ser integrada sem compilação e teste local.

Em suma, a equipa assume a responsabilidade integral por todas as decisões, análises, linhas de código e medições apresentadas neste relatório, garantindo que a IA atuou estritamente como um instrumento amplificador da capacidade técnica da equipa, e nunca como um substituto do julgamento crítico de engenharia de software.
