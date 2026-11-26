# Auditoria da Fase 2 · PictuRAS · PL3-G5

## 1. Parecer em 26/11/2026

**Os dois objetivos quantitativos estão demonstrados para a carga ensaiada. A submissão permanece por comprovar.** A espera média do primeiro vídeo do projeto B passou de 61,727085 s para 0,123429 s. Durante a execução de A, o utilizador passou de 6 para 12 ações bem-sucedidas em 12. Foram recontados os registos originais e passaram os 129 testes locais. A prioridade é fazer chegar ao avaliador o PDF e o pacote que permitem verificar estes números. O PDF de rascunho encontrado ainda apresenta 0,113 s, resultado de uma campanha anterior.

## 2. Referencial, caminhos e condições de repetição

- Todos os caminhos partem da raiz Git. Nesta auditoria, **G** designa `docs/fase-2-guidelines.md`, transcrição de `docs/fase-2-guidelines.pdf` (v1, 04/11/2026). **C/** designa `docs/src-doc-fase2-template/capitulos/`; **E/** designa `evaluation/evidence/`. Números após o caminho indicam linhas inclusivas. Salvo indicação, as linhas referem-se a `fa469819e5c879f02f1384a61ccfdec405fb78bb`. Os nomes dos arquivos nas instruções são locais, sujeitos a confirmação pelo docente.
- O projeto aplica um pipeline aos media de cada projeto. Na base, um trabalho de vídeo longo ocupa o único consumidor e o painel de processamento impede a utilização normal. QS-01 mede capacidade com dois projetos concorrentes. QS-02 mede operabilidade ao trabalhar no projeto B e retomar o acompanhamento de A.
- Base docente `phase2-base = 052310226c51fa57a17101c7bd1ad795674aac95`. A medição inicial usou `afb84e5`. O comando `git diff --exit-code phase2-base afb84e5 -- Tools projects frontend docker-compose.yaml users apiGateway wsGateway subscriptions imageStorageService rabbitMQ` passou. Revisão medida no fim `3cb1b7492b7688a87a076af6b0f6db576835a94d`. O único diff de aplicação dessa revisão até à árvore auditada é texto explicativo em `Tools/video/video.py:5-7`. Para consultar uma linha histórica, usar por exemplo `git show 0523102:Tools/video/video.py | nl -ba | sed -n '169,173p'`.
- Testes locais requerem Node, Python com pytest, o ambiente `Tools/video/.venv` e ffmpeg/ffprobe. A criação do ambiente consta de `AGENTS.md:106-111`. Para as campanhas usar uma stack dedicada, a conta premium e variáveis documentadas em `evaluation/README.md:6-46`, os ficheiros de teste com os hashes arquivados, Whisper aquecido e armazenamento para 16 volumes. O guia de reprodução indica Chrome, Playwright e as condições da base em `evaluation/phase2-reproduction.md:44-57`. O nome de uma conta ou a sua palavra-passe não pertence ao relatório.
- **Prova A — recontagem em diretório novo.** Executar o bloco seguinte na mesma shell. Um código diferente de zero interrompe a cadeia. O verificador final reconstrói as tabelas na cópia temporária.

```sh
(
  set -e
  raiz="$(pwd)"
  trabalho="$(mktemp -d)"
  cd "$raiz/evaluation/evidence"
  sha256sum -c picturas-phase2-final-3cb1b74.tar.gz.sha256
  tar -xzf picturas-phase2-final-3cb1b74.tar.gz -C "$trabalho"
  cd "$trabalho/phase2-final-3cb1b74"
  sha256sum --quiet -c SHA256SUMS
  python3 verify_final.py
  tar -xzf picturas-phase2-d01.tar.gz -C "$trabalho"
  cd "$trabalho/picturas-phase2-d01"
  sha256sum --quiet -c SHA256SUMS
  python3 evaluation/verify_phase2_evidence.py
)
```

## 3. Matriz de requisitos e evidência

PASS indica evidência suficiente no âmbito descrito. Parcial identifica uma reserva concreta. Pendente exige uma confirmação externa. As diretrizes não publicam pesos. A ordem de prioridade privilegia a entrega e as duas avaliações exigidas.

| ID e fonte | Obrigação ou critério | Estado e confronto com a fonte |
|---|---|---|
| R01 · G:18-20,47 | Dois RNF, ciclo completo e preservação funcional | PASS no âmbito testado. `C/06-candidatos-rnf.typ:22-24,43-50` individualiza QS-01 e QS-02. `C/08-decisoes-arquiteturais.typ:26-35,45-53` relaciona cada alteração com a fragilidade original. Regressões na secção 7. |
| R02 · G:22 | Prazo e defesas | Prazo de entrega indicado pela equipa: 27/11/2026. A auditoria não verificou recibo de submissão. |
| R03 · G:24-43 | Partir da solução PL1-G4 integrada, identificar commit, estudar documentação, arrancar e compreender o lote e as diferenças imagem/vídeo | Commit e arranque documentados em `C/01-introducao.typ:38-40`, `C/02-ambito-arquitetura.typ:29-37,129-141,156-158`. A extensão da Fase 1 é contexto. Legendas e fotogramas têm regras adicionais no repositório. Parcial quanto ao acesso às fontes herdadas citadas, B03. |
| R04 · G:49,55,59-65,102 | Classificar pela ISO/IEC 25010:2011, diagnosticar e justificar pertinência e complexidade para stakeholders | PASS. Capacidade, sob eficiência de desempenho, e operabilidade, sob usabilidade. Filas, concorrência, estado volátil, impacto e custo técnico constam de `C/06-candidatos-rnf.typ:22-24` e `docs/exercicios/RAS-exercicio_6_bloco2_SWdesign_template_PT.md:93-101`. |
| R05 · G:49-51,104-106 | Quantificar cada RNF com escala, carga, método, ambiente, instrumento, base, alvo, mínimo e origem | `C/06-candidatos-rnf.typ:43-50,56` e `docs/fase-2-plano-decisoes.md:23-29` fixam valores e identificam a decisão B-04. QS-01 alvo ≤15 s, mínimo ≤30 s. QS-02 alvo 12/12, mínimo 3/4 em cada ensaio, com navegação e recarga 3/3 e zero falsas conclusões. B03 explicita a justificação dos limiares para o leitor. |
| R06 · G:51,65,106,110 | Medir na base antes da mudança e repetir separadamente com método e condições comparáveis | Parcial quanto à identidade do ambiente. Prova A reproduziu a base oficial, a base repetida (82,242372 s) e o final. Carga e definição de espera mantidas. Mudaram instrumentação, condições de execução e, deliberadamente, o número de consumidores. O driver inicial de browser não foi preservado. `evaluation/phase2-reproduction.md:44-57`, `docs/sessoes/2026-11-24-validacao-entrega.md:52`. B05. |
| R07 · G:53 | Entregar cenários, scripts, dados e ambiente repetíveis | Pacote local íntegro, inclui amostras, instrumentos, manifesto e D-01. `evaluation/phase2-reproduction.md:3-13,32-48`. Parcial na distribuição e no encaminhamento do leitor para a campanha certa. B03, B06. |
| R08 · G:57,108 | Documentar ferramentas, skills, tarefas e validação pela equipa no relatório e no código/repositório | Parcial. `C/12-agentes-ia.typ:22-34,40-44` dá ferramentas, exemplo de erro e testes. Os registos acompanham o código em Git. Faltam confirmação humana e interpretação de «no código». B01, B04. |
| R09 · G:67,108 | Considerar alternativas, consequências, pré-requisitos e efeitos cruzados, implementar refactoring assistido | PASS. `C/08-decisoes-arquiteturais.typ:26-35,45-53`. Duas réplicas da fila existente, custos de memória e fechos simultâneos, persistência e custo de leitura/escrita. Implementação verificável em `projects/utils/processingRun.js:12,35,62` e `projects/utils/processingResult.js:1`. |
| R10 · G:67,110 | Comparar final com base/alvo, analisar limites e impactos noutros RNF | PASS para os ensaios. `C/10-tradeoffs-medicao.typ:74-76,88-104,113`. A RAM de pico média do grupo sobe de 3,051 para 4,252 GB. A menor espera de B não implica que todo o lote termine mais cedo. Divergência editorial entre capítulos em B03. |
| R11 · G:47,112 | Demonstrar preservação de imagem e vídeo por regressão | PASS nos percursos cobertos. Prova API com imagem, vídeos, lote misto, erro, frames, permissões e downloads em `docs/sessoes/2026-11-24-reentrega-resultados.md:15-18`. Cobertura executada nesta auditoria na secção 7. |
| R12 · G:69-98,114 | Distinguir ideias indicativas e regras formais de entrega | As ideias são exemplos. A v1 anuncia definição posterior de estrutura e entregáveis. Não especifica ZIP, pasta, tamanho, plataforma ou convenção de nomes. B01. |

## 4. Achados prioritários

1. **Risco de entrega.** Um clone normal omite a evidência. `git check-ignore evaluation/evidence/picturas-phase2-final-3cb1b74.tar.gz` confirmou a exclusão. O arquivo exterior é essencial para os números finais. O anexo só indica o arquivo interior.
2. **Risco de leitura errada.** 0,113 s está correto para a campanha anterior. O valor da decisão arquitetural fica sem data/revisão, ao lado de uma tabela final de 0,123 s. O rascunho PDF local tem 33 páginas e apresenta a série antiga. A compilação de 35 páginas registada em 25/11 foi feita noutra máquina.
3. **Defeito demonstrado no procedimento de revisão.** Os dois comandos de citações publicados em `AGENTS.md:154-155` falham antes de validar qualquer referência. Uma verificação auxiliar de 30 ocorrências literais de código/configuração entre plicas invertidas encontrou quatro caminhos abreviados. Há ainda uma referência de upload cujo intervalo termina antes de `validateVideo`.

## 5. Backlog executável

Esforços são estimativas de trabalho ativo, excluindo espera por resposta do docente. Estes itens são propostas de correção. A auditoria não modificou a aplicação, o relatório de entrega nem os exercícios.

| ID · prioridade · esforço | Dependência | Correção exata | Verificação de aceitação |
|---|---|---|---|
| B01 · média · 15 min | Nenhuma | Confirmar a versão vigente e o formato com a plataforma da UC ou o docente. O prazo indicado pela equipa é 27/11/2026. Registar grelha, canal, nome, formato, pastas, exclusões, estado de submissão e interpretação de «no código». | Cada campo tem fonte identificada ou indicação explícita de resposta pendente. Só marcar «submetido» perante recibo. |
| B02 · média · 45–90 min | Nenhuma | Reparar o procedimento de `AGENTS.md:154-155`. Disponibilizar `docs/exercicios/check_citations.py` e testes em `docs/exercicios/tests/` para caminho ausente, intervalo fora de limites e intervalo válido na revisão citada. Em `docs/exercicios/RAS_slides_aula6-bloco2_aula7-taticas_PT.md:260,327,328,330`, usar respetivamente `projects/utils/processBatch.js:11`, `Tools/video/video.py:169-173`, `Tools/video/video_processor.py:198-241`, `Tools/video/video.py:166-170` na base `0523102`. Em `docs/exercicios/RAS-exercicio_6_bloco1_SWdesign_template_PT.md:99` citar `projects/utils/video.js:84-110,115-143` para sondagem e limites. | Os dois comandos de `AGENTS.md:154-155` devolvem 0 e o checker rejeita uma referência inválida no teste negativo. Conferir que as linhas da base apoiam o texto com `git show 0523102:projects/utils/video.js`. |
| B03 · alta · 35–50 min | Nenhuma | Em `C/08-decisoes-arquiteturais.typ:29` identificar 0,113 s como D-01 anterior e 0,123 s como final em `3cb1b74`. Em `C/99-anexos.typ:15` indicar o arquivo exterior e o respetivo .sha256, incluir a Prova A da secção 2 e distinguir a recontagem da repetição ao vivo. Em `C/06-candidatos-rnf.typ:56` acrescentar a razão da escolha de 15/30 s e 4/4 ou 3/4 ações, confirmada por quem decidiu B-04. Em `C/02-ambito-arquitetura.typ:60-61` indicar origem e acesso aos documentos herdados efetivamente consultados. | Um leitor segue o anexo numa pasta vazia e obtém 0,123429 s e 12/12. O capítulo 8 identifica as duas campanhas. A justificação e as referências documentais podem ser confirmadas pela equipa. |
| B04 · alta · 30–45 min | B01, B03 | Um membro que conheça as intervenções revê `C/12-agentes-ia.typ:22-44`. Para cada ferramenta/skill confirmar tarefa, alterações, revisão, teste e limitação. Associar a intervenção ao símbolo e commit, por exemplo a persistência em `projects/utils/processingResult.js:1` com a regressão documentada em `docs/sessoes/2026-11-24-reentrega-resultados.md:13-18`. Registar revisor, data e conclusão. Se a orientação docente exigir atribuição no fonte, acrescentar a referência no módulo efetivamente assistido. | O registo de IA e o Git permitem localizar a intervenção e a prova. O revisor confirma a redação e o histórico `C/00-historico-versoes.typ:14-18` identifica a versão que reviu. |
| B05 · alta · 2–4 h | Nenhuma | Outro membro, em stack própria, executa a base e `3cb1b74` nas condições da secção 2. Seguir `evaluation/phase2-reproduction.md:44-57`: um aquecimento e três ensaios de cada cenário/configuração, filas inicialmente vazias. Guardar diretórios separados, hashes, versão, comandos, ações individuais, recuperações e diferenças de host/driver. Identificar como observação manual a base de browser. | Calcular média de B só nos três ensaios medidos; contar ações por ensaio, navegação, recarga, reconexão e conclusões prematuras. Confrontar com `C/06-candidatos-rnf.typ:48-50`. Assinar o resultado mesmo que divirja. |
| B06 · crítica · 30–45 min | B01, B03, B04; incorporar o resultado disponível de B05 | Compilar o PDF a partir de `docs/src-doc-fase2-template/main.typ:9-24` com `(cd docs/src-doc-fase2-template && typst compile --font-path fonts main.typ /tmp/picturas-fase2.pdf)`. Aplicar o nome autorizado. Preparar o pacote final e o .sha256 indicados na secção 2, conferir o conteúdo de distribuição e usar o canal autorizado pela equipa. | Extrair o texto do PDF com `pdftotext -layout /tmp/picturas-fase2.pdf -`; conferir capa, autores, QS-01, QS-02, anexo e orientação oculta. Abrir o PDF e inspecionar paginação das tabelas. Repetir a Prova A **na cópia destinada à entrega**, conferir recibo e data. |

## 6. Ordem de execução recomendada

1. **B01** primeiro, dada a data publicada. Se a resposta demorar, iniciar os três itens independentes seguintes.
2. **B05**, para dar tempo à campanha independente. Ponto de controlo: revisões, amostras e número de consumidores identificados antes da primeira medição.
3. **B02**. No fecho deste item, ambos os comandos de citações devem passar.
4. **B03**. O anexo deve reproduzir os números do capítulo 10 a partir do pacote final.
5. **B04**. Após a conferência humana, fechar o histórico e fixar a revisão documental.
6. **B06**. O relatório deve compilar e a cópia de distribuição deve passar a Prova A. Encerrar o estado administrativo perante comprovativo.

## 7. Resultados dos testes · Fase 4

| Verificação | Resultado e alcance | Comando a partir da raiz, salvo indicação |
|---|---|---|
| Orquestrador e reconciliação do frontend | PASS 38/38, zero ignorados | `node --test projects/tests/*.test.js frontend/tests/processing-status.test.mjs` |
| Instrumentos | PASS 14/14 | `PYTHONDONTWRITEBYTECODE=1 python3 -m pytest -p no:cacheprovider -q evaluation/tests` |
| Vídeo, legendas, fotogramas e mensagens | PASS 77/77; aviso de descontinuação de Pillow em `Tools/video/tests/test_subtitles.py:49` | `PYTHONDONTWRITEBYTECODE=1 Tools/video/.venv/bin/python -m pytest -p no:cacheprovider -q Tools/video/tests` |
| Configuração Compose | PASS, saída 0 | `docker compose config --quiet` |
| Imagem de produção do frontend | PASS, Docker reutilizou a camada `RUN bun run build`. Compilação limpa histórica em `docs/sessoes/2026-11-24-validacao-entrega.md:90` | `docker build --progress=plain -t picturas-audit-frontend:fa46981 ./frontend` |
| Integridade do pacote final e D-01 | PASS, checksum exterior, 45 entradas finais e 141 interiores | Prova A, secção 2 |
| QS-01 · recontagem da capacidade | PASS. Base oficial 61,855105 / 61,935791 / 61,390359 s. Final 0,112955 / 0,137493 / 0,119838 s. Médias 61,727085 e 0,123429 s | Prova A. O cálculo no runner está em `evaluation/run_scenario.py:383`, função `calculate_metrics`. |
| QS-02 · recontagem do browser | PASS. Base 6/12, navegação e recarga 0/3. Final 12/12, navegação, recarga e reconexão 3/3 cada, zero conclusões prematuras | Prova A. `E/phase2-final-3cb1b74/verify_final.py:69,115`, funções `browser_row` e `main`. |
| Citações dos exercícios | **FAIL → B02**, código 2, script ausente | `python3 docs/exercicios/check_citations.py` |
| Testes do verificador | **FAIL → B02**, código 4, diretório ausente, zero testes recolhidos | `python3 -m pytest -p no:cacheprovider docs/exercicios/tests/ -q` |
| Concorrência MongoDB e reentrega | Histórico: cinco casos passaram; inclui interrupção após gravação e duas entregas simultâneas | `docker run --rm --network picturas-validation_elk picturas-validation-projects-redelivery:local node /app/tests/project-concurrency.integration.js`, com Mongo da stack dedicada; fonte `docs/sessoes/2026-11-24-reentrega-resultados.md:17`. |
| Regressão API, permissões e quota | Histórico: imagem, dois vídeos, lote misto, falha de trim, três frames, permissões e downloads; reembolso F8 verificado separadamente | Na stack de validação: `python3 evaluation/evidence/phase2-validation-2026-11-24-redelivery/check_integrated.py` e `python3 evaluation/check_video_quota_refund.py`. Fontes `docs/sessoes/2026-11-24-reentrega-resultados.md:18` e `docs/sessoes/2026-11-24-validacao-entrega.md:82-84`. |
| QS-03 e custo do polling | Histórico: duas interrupções de worker e duas de broker recuperadas; experiência separada com um observador a 1 Hz | Stack dedicada com fila vazia. Executar os três comandos de `evaluation/README.md:111-113`; para uma segunda interrupção usar nomes de saída diferentes. |
| Campanhas ao vivo | Não repetidas nesta auditoria. B05. A base e o final arquivados foram recontados acima. | Capacidade: `python3 evaluation/run_scenario.py --warmup 1 --runs 3 --expected-workers 2 --output-dir evaluation/evidence/audit-final-capacity`; na base usar 1 e diretório novo. Browser final: comando e variáveis de `evaluation/phase2-reproduction.md:50-55`. |
| Compilação e leitura visual do Typst atual | Não executadas aqui, sem Typst no PATH. Última compilação registada: 35 páginas, verificação visual das páginas 13 e 14 em `docs/sessoes/2026-11-25-revisao-relatorio-inicial.md:88`. | Comando de B06 ou `(cd docs/src-doc-fase2-template && typst compile --font-path fonts main.typ /tmp/picturas-fase2.pdf)`. |

## 8. Relatório e restantes entregáveis · Fase 5

| Entregável inspecionado | Edição concreta ou ação de entrega |
|---|---|
| Relatório Typst, capa, histórico e PDF | Preservar grupo e quatro autores de `docs/src-doc-fase2-template/main.typ:14-24`, confirmar grafia com a equipa; manter `mostrar-orientacoes.update(false)` na linha 12. Substituir a referência isolada a 0,113 s e atualizar anexo e histórico (B03/B04). Gerar PDF da revisão aprovada (B06). `docs/template-fase2-preview.pdf` é pré-visualização; `E/picturas-phase2-relatorio-rascunho.pdf` é o rascunho antigo. |
| Cenários, instrumentos, dados e ambiente | Entregar o arquivo exterior e digest como conjunto. O arquivo inclui D-01, registos de capacidade e browser, imagens/limites, manifestos, scripts e a prova de reentrega. Inventário em `E/phase2-final-3cb1b74/README.md:5-13`. Acrescentar ao anexo o caminho de obtenção acessível ao avaliador (B03/B06). |
| Repositório e testes | Preservar revisões de base e final; indicar o commit distinto da versão documental aprovada. Reparar as referências e os dois comandos de revisão (B02). |
| Registo de IA e revisão independente | Completar identificação da validação humana e anexar a folha de execução independente com versão, desvios e resultados (B04/B05). |
| Documentos herdados e regras administrativas | Disponibilizar referência resolúvel aos documentos de base citados. Obter grelha e comprovativo; incorporar requisitos adicionais que a versão oficial trouxer (B01/B03). |

## 9. Checklist final de submissão

As caixas são para a equipa marcar sobre a cópia efetivamente entregue.

- [ ] Confirmar a versão do enunciado, a grelha e a plataforma com o docente/UC.
- [ ] Confirmar formato e regras vigentes. Prazo de entrega indicado pela equipa: 27/11/2026. Guardar comprovativo de submissão com data.
- [ ] Aplicar o nome exato, formato, pasta e limite de tamanho oficialmente comunicados. Se não houver convenção, registar essa confirmação.
- [ ] Incluir relatório aprovado, com grupo, quatro autores, base, revisão medida, dois RNF, alternativas, regressões, custos e IA.
- [ ] Incluir fonte/referência Git acessível, cenários, scripts, amostras, ambiente e condições de repetição.
- [ ] Disponibilizar `picturas-phase2-final-3cb1b74.tar.gz` e `picturas-phase2-final-3cb1b74.tar.gz.sha256` ou os equivalentes formalmente exigidos. Confirmar acesso com a cópia de destino.
- [ ] Incluir a revisão humana e identificar o estado real da reprodução independente.
- [ ] Aplicar a convenção do repositório em `AGENTS.md:126`: excluir de novos ficheiros de código segredos, `.env`, `node_modules/`, media gerados e `backups/`. Na evidência conservar as amostras e resultados previstos no manifesto. Conferir exclusões do docente separadamente.
- [ ] Excluir da seleção de relatório final a pré-visualização e o PDF antigo; excluir notas temporárias, caches e ficheiros de trabalho.
- [ ] Abrir o PDF entregue, confirmar que o anexo aponta para o pacote entregue e validar ambos os manifestos pela Prova A.

## 10. Ambiguidades e decisões

| Ponto | Interpretações e decisão recomendada | Pergunta a resolver |
|---|---|---|
| Formato e prazo | A v1 remete o formato para versão posterior. O template e D-01/D-02 são instrumentos locais. Usá-los na preparação; aplicar as regras efetivamente publicadas na entrega. | Qual é a versão vigente, grelha, canal, convenção de nomes/pastas e prazo aplicável ao PL3-G5? Existe recibo ou extensão? |
| «Mesmas condições» | Pode significar igualdade estrita da stack ou equivalência do cenário com variação da réplica em teste. Declarar ambas as séries de uma réplica, versões e mudanças de instrumento: a magnitude exata depende dessas condições. | A comparação documentada e a base repetida são suficientes face à indisponibilidade do driver histórico? |
| «No código» | Registo em documentação versionada ou atribuição junto de cada intervenção no fonte. Preferir ligação módulo/símbolo/commit/teste e confirmar o nível de anotação exigido antes de alterar módulos. | A UC aceita o registo versionado e rastreável, ou exige anotação por ficheiro? |
| Complementos QS-03 e validação independente | QS-03 é regressão de fiabilidade. Os candidatos avaliados continuam a ser QS-01 e QS-02. A reprodução por terceiro é trabalho assumido pela equipa; a v1 exige que a medição seja repetível. | Confirmar se a grelha posterior exige anexar execução por terceiro. |

## 11. Opcional / fora de âmbito

Não iniciar por defeito autoscaling, separação do worker de legendas, alteração dos contratos AMQP, ensaio de carga com múltiplos observadores ou migração de armazenamento. A v1 apresenta ideias alternativas em G:69-98. Nenhuma é necessária para explicar ou recontar os resultados escolhidos.

## 12. Limitações e auto-verificação

- O pedido recebido começa na secção 6. A organização das secções 1–5 foi reconstruída a partir da matriz e do backlog pedidos. O âmbito auditado é a entrega da Fase 2 descrita na v1 local. A especificação PL1-G4 descreve o MVP herdado. Não foi feita uma nova homologação individual de todos os requisitos da Fase 1.
- Sem grelha posterior, acesso à plataforma, resposta do docente ou recibo, a auditoria não estabelece classificação, formato oficial ou submissão. A identidade dos autores e os atos da equipa carecem de confirmação pelos próprios.
- Os dados locais comprovam as observações arquivadas. A auditoria não criou contas, executou uma campanha independente, interrompeu serviços nem ensaiou o sistema multiutilizador sob nova carga. O Compose corrente apresentava só parte dos serviços em execução. As suites e o build em cache têm o alcance indicado na secção 7.
- Sem o compilador Typst instalado, a inspeção atual cobriu a fonte, o texto do PDF de rascunho e o registo anterior de compilação. A correspondência visual do PDF a entregar e a revisão documental atual continuam pendentes.
- Na ausência do verificador prescrito, a inspeção mecânica auxiliar comparou com a base os limites de 30 citações literais de ficheiros JS/TS/TSX/Python/YAML/JSON em Markdown dos exercícios. Não valida semanticamente todas as citações em texto livre, figuras ou PDF.
- **Auto-verificação:** as obrigações explícitas da v1 estão na matriz; ambos os FAIL remetem a B02; cada item B01–B06 indica edição/ação, dependência, aceitação e esforço. As correções propostas concentram-se em provas e entrega. Os artefactos identificáveis foram inventariados; os que dependem do docente ou de confirmação humana estão marcados. Nenhuma caixa de submissão foi dada como concluída sem comprovativo.
