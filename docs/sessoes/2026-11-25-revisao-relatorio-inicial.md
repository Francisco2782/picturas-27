# Revisão inicial do relatório da Fase 2

## Âmbito

Revisão do rascunho Typst, após autorização do utilizador. Não foram alterados código nem dados de medição.

## Decisões e alterações

- A tabela de artefactos da introdução identifica o repositório entregue (`Francisco2782/picturas-27`, branch `main`) separadamente do repositório de origem da baseline (`picturas-um/picturas-27`).
- No capítulo 2, a referência ao commit e ao checkout de medição esclarece que pertencem ao repositório de origem da baseline.
- O parágrafo sobre o fluxo de processamento foi condensado e identificado como descrição da revisão validada. A sequência foi conferida com `projects/routes/projects.js`, `projects/utils/processBatch.js`, `projects/utils/project_msg.js`, `Tools/video/video.py` e `wsGateway/index.js`.
- Removidas as duas notas editoriais do capítulo 2. A secção sobre a bifurcação entre imagem e vídeo foi mantida, por estar alinhada com o âmbito indicado na introdução.
- Corrigida a frase de enquadramento da vista da arquitetura.
- A atribuição a Codex (GPT-6) foi mantida conforme confirmado pelo utilizador. A referência à skill PDF também foi mantida conforme decisão do utilizador.
- A tabela e os parágrafos de medição do capítulo 10 foram alinhados com a validação final `3cb1b74`, em vez de apresentarem como finais os números da campanha de 22/11. As métricas da campanha de 22/11 permanecem como comparação histórica.
- Após clarificação, a tabela-resumo QS-01 foi alinhada com os 0,123 s médios da validação `3cb1b74`; o valor de 0,113 s fica associado à campanha de 22/11.
- A contagem de 76 testes do worker foi limitada à validação R-01 a R-04 de 22/11; os 77 testes executados no seguimento QS-03 são agora identificados separadamente.

## Verificações executadas

- `git remote get-url origin`: confirmou `git@github.com:Francisco2782/picturas-27.git`.
- `git diff --check`: passou.
- `rg -n 'NOTA:|PREENCHER' docs/src-doc-fase2-template/capitulos/01-introducao.typ docs/src-doc-fase2-template/capitulos/02-ambito-arquitetura.typ`: não encontrou notas ou campos por preencher nos capítulos editados.
- Na primeira fase desta revisão, `command -v typst` não devolveu caminho; ainda não era possível compilar o relatório nem confirmar a paginação do parágrafo no PDF.
- Conferência dos valores finais com `docs/sessoes/2026-11-24-validacao-final-3cb1b74.md` e dos valores históricos de 22/11 com `docs/sessoes/2026-11-22-fecho-fase-2.md`.
- `rg -n '0,113|0,123|80,961|89,749|9,676|10,347|6,153|7,243|4,289|4,252' docs/src-doc-fase2-template/capitulos/10-tradeoffs-medicao.typ`: confirmou os novos agregados e permitiu identificar os números históricos restantes.
- A árvore estava limpa antes do trabalho. As alterações atuais são documentais e permanecem sem commit.

## Por confirmar

- A revisão humana integral do relatório e a reprodução independente das medições continuam pendentes, conforme os registos da Fase 2.

## Fecho

Foram feitas alterações autorizadas aos capítulos 1, 2 e 10 e registadas aqui. A sintaxe foi verificada por inspeção e `git diff --check`; a compilação e a triagem visual de todas as páginas foram concluídas no aditamento abaixo. A revisão humana integral e a reprodução independente permanecem pendentes.

## Aditamento — auditoria de rastreabilidade e correções autorizadas

### Problemas confirmados

- A numeração do relatório não correspondia à primeira utilização: `EV-10` surgia no parágrafo do capítulo 2 antes de `EV-01`, e os capítulos 3, 5, 6 e 7 ainda apontavam para a numeração do Exercício 6. O registo anterior de renumeração dizia que estes capítulos já tinham sido atualizados, mas a leitura dos ficheiros mostrou que não.
- A linha de upload citava `projects/routes/projects.js:1564-1671`, que é o fluxo de processamento, e `projects/utils/video.js:14-80`, que não contém a função de validação. A rota e o handler de upload estão em `projects/routes/projects.js:1275-1317, 1390-1394`; a sondagem e validação estão em `projects/utils/video.js:84-143`, na baseline `0523102`.
- A referência `projects/utils/processBatch.js:88-142` também excedia o ficheiro: a função ocupa as linhas 1-12 na baseline e na revisão final. A citação foi corrigida para `:1-12`.
- A linha sobre os trabalhadores citava apenas o Compose para sustentar também a passagem única dos efeitos de vídeo. A referência foi completada com `Tools/video/video_processor.py:190-218, 316-363`, que mostra uma descodificação/codificação para o grupo de efeitos e a separação de etapas por legendagem.
- A referência `Tools/video/video.py:140` apontava para o ack de mensagens inválidas, não para o ack após processamento. A chamada síncrona ao processador e o ack do trabalho estão em `150-170`; o `prefetch_count` e `auto_ack=False` estão em `54` e `172-174`.
- `Tools/utils/rabbit_mq.py:28-35` não continha `auto_ack=True`; a chamada está em `37-41` na baseline.
- O snapshot durável precisava de citar a atualização condicional em `projects/controllers/project.js:96-123`. A criação de `Result` e o commit do projeto são operações distintas; o texto já não as descreve como uma criação atómica de resultados.
- A tabela misturava o percurso de progresso da revisão validada (`3cb1b74`) com referências à baseline `0523102`. O texto agora identifica a mudança de publicação direta em `ws_queue` para `project_queue`, com persistência no orquestrador antes da notificação.
- “Reprodutibilidade integral” excedia a evidência disponível: a reprodução independente continua pendente e o arquivo não inclui a imagem original do worker nem o driver histórico exato do navegador. A afirmação foi reduzida para descrever o registo realizado e as limitações existentes.
- “Vídeo não é convertível para PDF” era uma generalização. O relatório agora limita a afirmação ao comportamento da aplicação: não disponibiliza exportação PDF em projetos com vídeo.

### Alterações autorizadas realizadas

- Reindexadas as evidências na ordem efetiva: `EV-01` TLS interno, `EV-02` publicador RabbitMQ, `EV-03` upload/despacho, `EV-04` worker, `EV-05` legendagem, `EV-06` estado persistido, `EV-07` rota de estado, `EV-08` réplica por omissão, `EV-09` `auto_ack` de imagem e `EV-10` UI da baseline.
- Atualizadas as referências nos capítulos 2, 3, 4, 5, 6 e 7. As hipóteses `H-01` a `H-04` foram explicitadas nos respetivos pontos de primeira utilização, com método e estado; os resultados finais usam 0,123 s para a espera de B, 12/12 ações e 3/3 recuperações.
- Corrigida a citação da rota de upload, a distinção entre validação por extensão/MIME e metadados obtidos por ffprobe, as linhas de ack e a descrição de resultados sem afirmar atomicidade inexistente.
- Em `docs/EXPLICACAO_PROJETO.md`, clarificado que os documentos de exercícios preservam os IDs originais; acrescentada a correspondência para a numeração do relatório final; corrigido o total de hipóteses do Exercício 6 de cinco para quatro.
- Acrescentado um aditamento ao registo de renumeração de 24/11 para marcar explicitamente o mapa anterior como substituído, sem apagar o histórico da decisão.
- Na auditoria inicial, a docstring de `Tools/video/video.py` dizia que o progresso ia diretamente para `ws_queue`, embora o worker publique em `project_queue`. Após autorização explícita do utilizador em 25/11, a docstring foi corrigida para descrever o percurso via orquestrador.

### Verificações

- As fontes foram conferidas em `git show 0523102:...` e `git show 3cb1b74:...` para separar baseline e revisão final.
- `rg` foi usado para conferir os usos de `EV-nn` e `H-nn` nos capítulos e os IDs originais no Exercício 6.
- `git diff --check`: passou depois das correções.
- A pesquisa por referências desatualizadas de upload, despacho, ack e `auto_ack` nos capítulos 1-10 não encontrou ocorrências; a referência corrigida `processBatch.js:1-12` foi confirmada na baseline e na revisão final.
- As linhas 15-21 e 60-63 de `Tools/video/subtitles.py` foram confirmadas na baseline. A citação `processBatch.js:88-142` aparece neste registo apenas para documentar o erro detetado, não como referência do relatório.
- As linhas 190-218 e 316-363 de `Tools/video/video_processor.py` foram confirmadas na baseline e sustentam a passagem única por grupo de efeitos e a divisão de etapas por legendagem.
- Na altura deste aditamento de auditoria, Typst ainda não estava disponível; a instalação e a compilação foram registadas no aditamento final abaixo.

## Aditamento — instalação e compilação Typst

- `brew install typst` começou a compilar 12 fórmulas a partir do código-fonte neste Mac Intel/macOS 14, com cerca de 10 GiB disponíveis. Interrompi essa instalação durante a compilação de CMake para evitar uma compilação extensa e possível falta de espaço; como efeito parcial, CMake 4.5.1 foi instalado e `pkgconf` atualizado de 3.0.10 para 3.0.11.
- Instalei o binário oficial Typst 0.15.1 para `x86_64-apple-darwin` em `/usr/local/bin/typst`. O SHA-256 local (`7f9fdd9584866245de9a79e0add8f9236fae6f40a8a45e2c4771ccc14db4e0fa`) corresponde ao digest publicado pela release `v0.15.1`; `typst --version` confirmou `0.15.1`.
- `cd docs/src-doc-fase2-template && typst compile --font-path fonts main.typ /tmp/picturas-phase2-review.pdf`: terminou com código 0. A primeira versão tinha 36 páginas; após a revisão do layout, a versão final tem 35 páginas físicas.
- Foram criadas folhas de contacto e feita triagem visual de todas as 35 páginas; as páginas físicas 12-14, 18-19 e 30-31 também foram inspecionadas em maior resolução. Na Figura 2, os rótulos do worker ultrapassavam o `viewBox` de `sequencia_pedido.svg`; alarguei-o e recentrei o título, e a nova renderização confirmou que cabem.
- A Tabela 6 foi movida para uma página horizontal, as citações foram compactadas sem remover as referências de origem e a tabela passou a caber numa página, sem partir linhas. Não foram observados outros cortes de texto na triagem visual.
- Testei colocar a secção 4.4 na mesma página horizontal da matriz; o texto ficou excessivamente largo numa página ainda esparsa, por isso mantive essa secção em retrato. A página tem espaço em branco, mas o conteúdo permanece legível.
- Após autorização explícita do utilizador, corrigi apenas a docstring de `Tools/video/video.py`: o worker publica progresso em `project_queue`, e o orquestrador encaminha as atualizações para `ws_queue`. O trecho foi conferido com o publisher `_progress` no próprio ficheiro.
- A revisão humana integral e a reprodução independente permanecem pendentes.
- O PDF e as imagens temporárias foram usados apenas para validação; não foram adicionados ao repositório. Na aplicação, foi alterada somente a docstring; o comportamento executável não mudou.

## Aditamento — revisão do capítulo 2

- Corrigida a citação inválida `AGENTS.md:168-169` para `AGENTS.md:119-120` na revisão `0f6dbc5`; o ficheiro citado tem 127 linhas e os números antigos não existiam.
- A referência a `Tools/video/subtitles.py` não sustentava a afirmação sobre eventos de progresso. Removi-a e documentei `EV-06` no primeiro uso com as fontes da mensagem `video-progress`, validação do token, persistência e encaminhamento WebSocket na revisão `3cb1b74`.
- `H-01` surgia apenas como rótulo, sem hipótese, método ou estado. O texto agora descreve a condição de corrida, a regressão com barreira que a reproduziu e a validação P-02 dos dois resultados após a correção.
- Esclareci que o `ack` confirma a entrega original em `video_queue`, não a resposta em `project_queue`; acrescentei referências para persistência, commit condicional e `process-update`.
- Corrigi o suporte para efeitos de fotograma contíguos e para as ferramentas visíveis por tipo de projeto; substituí também a formulação determinista de que o vídeo “obrigou” a uma bifurcação por uma descrição do desenho implementado.
- `typst compile --font-path fonts main.typ /tmp/picturas-ch2-review.pdf`: passou, 35 páginas. Inspecionei visualmente as páginas físicas 13 e 14; as tabelas continuam numa página cada, sem cortes. `git diff --check`: passou.
