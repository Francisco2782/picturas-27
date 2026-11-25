# Sessão 2026-11-24 — Renumeração de evidências e hipóteses (EV-nn, H-nn)

## Problema

O template (secção 2.4, orientações) exige que o ID de evidência/hipótese seja sequencial pela ordem de
primeira utilização no relatório: *o ID é sequencial (`EV-01`, `EV-02`, …), único, e nunca se reutiliza*.
O rascunho atribuía os IDs numa tabela de registo no fim do capítulo 2 ("Registo formal de evidências e
hipóteses"), sem respeitar essa ordem. Na prosa, a primeira utilização seguia outra sequência:

- EV (prosa): EV-04 → EV-01 → EV-03 → EV-06 → EV-10 → EV-07 → EV-05 (cap. 2), EV-09 (cap. 4);
  EV-08 nunca era usada na prosa (só na tabela de registo).
- H (prosa): H-04 (cap. 3), H-01 e H-02 (cap. 4); H-03 nunca era usada na prosa.

## Numeração final aceite

Depois de duas iterações com a equipa, o estado final é o seguinte (a primeira coluna é o ID do template
inicial, a última é o ID final, válido em todo o relatório):

| Antigo (template) | Final | Primeira utilização (com descrição completa) |
|-------------------|-------|-----------------------------------------------|
| EV-04 | **EV-01** | cap. 2, `tab-passos-pedido` (Carregamento): `projects/routes/projects.js:1564-1671` + `projects/utils/video.js:14-80` — despacho bifurcado e validação ffprobe |
| EV-01 | **EV-02** | cap. 2, `tab-passos-pedido` (Submissão): `Tools/video/video.py:54, 140, 170, 174` — `prefetch_count=1`, modelo síncrono, `basic_ack` no fim |
| EV-03 | **EV-03** (inalterado) | cap. 2, `tab-passos-pedido` (Progresso): `Tools/video/subtitles.py:15-21, 60-63` — Whisper síncrono CPU/int8 |
| EV-06 | **EV-04** | cap. 2, `tab-passos-pedido` (Progresso): `projects/models/project.js:35-65`, `processingRun.js` — snapshot atómico |
| EV-10 | **EV-05** | cap. 2, `tab-passos-pedido` (Progresso): endpoint `GET …/processing-status` |
| EV-02 | **EV-06** | cap. 2, `tab-bifurcacao-media` (Execução): `docker-compose.yaml:255-260` — réplica única |
| EV-07 | **EV-07** (inalterado) | cap. 2, `tab-bifurcacao-media` (Confirmação AMQP): `Tools/utils/rabbit_mq.py:28-35` — `auto_ack` imagem |
| EV-05 | **EV-08** | cap. 2, `tab-bifurcacao-media` (Interface): `frontend/app/dashboard/[pid]/page.tsx` — estado volátil + modal |
| EV-09 | **EV-09** (inalterado) | cap. 4, matriz (Segurança TLS interno: `apiGateway/routes/projects.js:18`, `rejectUnauthorized: false`) |
| EV-08 | **EV-10** | cap. 2, parágrafo "Como é orquestrado o processamento em lote": `projects/utils/rabbit_mq.js:11-30` — ligação AMQP por operação. Citado antes de EV-01 por opção da equipa (ordem narrativa); a tabela `tab-passos-pedido` é quem abre a sequência |
| H-03 | **H-01** | cap. 2, `tab-passos-pedido` (Consolidação): corridas no fecho do lote, deinjetadas por finalizações concorrentes; confirmada na auditoria e corrigida na prova P-02 |
| H-04 | **H-02** | cap. 3: estrangulamento de I/O em `image_data`; método: monitorização de I/O; por confirmar (fora do âmbito) |
| H-01 | **H-03** | cap. 4, matriz (temporal): duas réplicas reduzem a espera de B; confirmada — 0,113 s (`M-02`) |
| H-02 | **H-04** | cap. 4, matriz (usabilidade): snapshot + painel desacoplado; confirmada — 12/12 ações e 3/3 recuperações no Chromium |

## O que foi feito nas outras frentes da mesma regra

- Removida a secção "Registo formal de evidências e hipóteses" (tabelas `tab-registo-evidencias` e
  `tab-registo-hipoteses` e o parágrafo introdutório) do capítulo 2 — a regra manda descrever a evidência no
  sítio da primeira utilização, não num registo separado.
- Cada evidência/hipótese descreve-se agora nesse sítio, no formato `EV-nn`: localização — o que mostra
  (e `H-nn` com formulação, método de confirmação e estado).
- Os intervalos "`EV-01` a `EV-03`" (caps. 5, 6 e 7) foram convertidos em listas explícitas
  (`EV-02`, `EV-03`, `EV-06`) para representarem o mesmo conjunto de três evidências.
- Os caps. 1, 12 e anexo referem só intervalos globais (`EV-01` a `EV-10`, `H-01` a `H-04`), que continuam
  válidos e não foram alterados.
- O exemplo genérico das regras do template (bloco de orientações, "(`EV-01`, `EV-02`, …)") foi preservado.

## Incidente registado

Durante as iterações, operações de regex em perl aplicaram rotações parciais e duplicadas (a rotação `-1`
correu duas vezes no cap. 2 e colapsou vários IDs em `EV-01`; o exemplo das regras ficou
"(`EV-01`, `EV-01`, …)"). O capítulo 2 foi reparado célula a célula pelo conteúdo, com verificações
independentes de identidade e ordem no fim.

## Verificação final (célula a célula, por conteúdo)

- Ordem de primeira utilização: EV-10 (cap. 2:43, exceção consciente) → EV-01…08 (tabelas do cap. 2) →
  EV-09 (cap. 4); H-01 (cap. 2), H-02 (cap. 3), H-03/H-04 (cap. 4). Únicos, sem reutilizações.
- Listas dos caps. 5-7 coerentes com a identidade: `EV-02`,`EV-03`,`EV-06` = vídeo/legendagem/réplica única;
  `EV-08` = frontend; `EV-02`,`EV-07` = perda de mensagens; `EV-04` = snapshot.
- Sem resíduos de âncoras nem IDs inválidos (`EV-00`, `EV-1[1-9]`, `EV-11`+).
- `typst compile --font-path fonts main.typ` termina com código 0 (só warnings de formatação pré-existentes).

## Resumo

- Numeração de EV-01…EV-10 e H-01…H-04 uniforme em todo o relatório, descrita na primeira utilização, registo
  separado eliminado — em conformidade com a regra da secção 2.4 do template.

## Por verificar / não feito

- Re-leitura integral do PDF renderizado (além da compilação) e revisão por outro elemento da equipa.
- Os warnings pré-existentes de Typst (`**classe**` nos caps. 3 e 12) foram mantidos intencionalmente.

## Aditamento de 25/11 — correção após auditoria de rastreabilidade

A revisão posterior encontrou dois problemas que invalidavam a verificação acima: `EV-10` era citado na prosa do
capítulo 2 antes de `EV-01`, e os capítulos 3, 5, 6 e 7 ainda continham várias referências com a numeração original.
Além disso, a citação do upload apontava para o handler de processamento, não para a rota de upload, e alguns
intervalos de linhas não continham o facto atribuído.

Com autorização do utilizador, o relatório foi corrigido e a numeração foi refeita pela ordem efetiva da primeira
utilização: `EV-01` TLS interno, `EV-02` publicador RabbitMQ, `EV-03` upload e despacho, `EV-04` worker de vídeo,
`EV-05` legendagem, `EV-06` estado persistido, `EV-07` rota de estado, `EV-08` réplica por omissão, `EV-09`
`auto_ack` das ferramentas de imagem e `EV-10` interface da baseline. A correspondência com os IDs originais do
Exercício 6 está registada em `docs/EXPLICACAO_PROJETO.md` e os detalhes da correção em
`docs/sessoes/2026-11-25-revisao-relatorio-inicial.md`. Esta correção substitui o mapa e a declaração de verificação
final registados acima.
