# Validação técnica da Fase 2

Revisão da aplicação `fb18924`. A `main` estava limpa e alinhada com a referência local de `origin/main` no início. A base da Fase 2 é `phase2-base` (`0523102`). Esta sessão prepara evidência para a equipa rever e usar posteriormente no relatório.

## Critérios e âmbito

| Critério | Estado | Evidência |
| --- | --- | --- |
| Requisitos docentes | V1 local consultada | A V1 pede dois requisitos não funcionais mensuráveis, refactoring com preservação funcional e evidência reproduzível. O formato de entrega é remetido para uma versão posterior. [Diretrizes](../fase-2-guidelines.md) |
| Extensibilidade da capacidade | Verificada no código e na configuração | O worker, o pipeline, a fila e os nomes de serviço são reutilizados. O Compose base mantém uma réplica. A stack dedicada mostrou dois consumidores `video_queue` com `prefetch=1`. [Compose](../../docker-compose.yaml) · [Worker](../../Tools/video/video.py) |
| Operabilidade durante o processamento | Cenário executado | O gateway expõe um snapshot autorizado, `projects` é a fonte de estado e a interface combina snapshots e eventos com identificação do projeto e execução. A campanha em Chromium completou os três ensaios e o aquecimento. |
| Comparação com a base | Evidência histórica verificada | A extração local do D-01 confirmou os hashes e reproduziu os agregados. A imagem original do worker da base e o driver histórico exato do browser estão indisponíveis. [Guia de reprodução](../../evaluation/phase2-reproduction.md) |
| Validação humana | Pendente com a equipa | Reprodução independente, revisão do relatório e do registo de IA e confirmação da grelha e submissão. |

## Comandos e observações iniciais

- `node --test projects/tests/*.test.js frontend/tests/processing-status.test.mjs` passou 38 casos. `PYTHONDONTWRITEBYTECODE=1 python3 -m pytest -p no:cacheprovider -q evaluation/tests` passou 14. O mesmo comando com `Tools/video/.venv/bin/python` e `Tools/video/tests` passou 77, com um aviso de depreciação do Pillow em `test_subtitles.py`.
- `git diff --check phase2-base..HEAD -- Tools/video apiGateway frontend projects users wsGateway evaluation` e `docker compose config --quiet` passaram. O diff de `docker-compose.yaml` e `rabbitMQ/definitions.json` face a `phase2-base` estava vazio.
- A stack `picturas-validation` tinha MongoDB, RabbitMQ, frontend e nginx parados. Arranquei apenas os contentores existentes da stack dedicada. A primeira tentativa de registar uma conta premium obteve HTTP 500 porque o `nodemon` tinha ficado com os processos `users` e `subscriptions` parados. Reiniciei esses dois serviços após a subida do MongoDB. O Chromium conseguiu registar a conta e executar o cenário.
- Confirmei os SHA-256 do código local e em execução das rotas e do controlador de `projects`, do consumidor RabbitMQ de `projects`, dos módulos `video.py`, `video_processor.py` e `progress.py`, e de `wsGateway/index.js`. O frontend já em execução corresponde à imagem de validação usada anteriormente. `24c1266` é o último commit que altera o frontend. O comando `docker build --progress=plain -t picturas-validation-frontend:closeout ./frontend` terminou com sucesso, com a etapa de compilação em cache.
- Corri o driver arquivado `browser_u04.py warmup trial-1 trial-2 trial-3` em Chrome 157.0.8103.50 com Playwright 1.65.2. Cada resultado descarregado tem o mesmo SHA-256 que o vídeo captionado já verificado na campanha arquivada. `ffprobe` confirmou H.264 e AAC.

## QS-02 · Operabilidade em Chromium

Conta premium, viewport 1280×720, projetos A/B novos em cada ensaio, o mesmo clip de fala de 10 s da baseline. Durante a legendagem em A, o driver abriu B, usou a toolbar, regressou a A e confirmou o progresso. Também recarregou a página, interrompeu a ligação e verificou o restabelecimento do WebSocket.

| Ensaio | Ações | Navegação | Recarregamento | Reconexão | Conclusões prematuras | Duração (s) | Pedidos API / estado | Frames WS / progresso | Percentagens repetidas / descidas |
| --- | ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Aquecimento | 4/4 | OK | OK | OK | 0 | 10,380 | 43 / 11 | 86 / 78 | 27 / 4 |
| 1 | 4/4 | OK | OK | OK | 0 | 9,561 | 43 / 11 | 84 / 76 | 27 / 1 |
| 2 | 4/4 | OK | OK | OK | 0 | 8,009 | 41 / 9 | 78 / 70 | 22 / 0 |
| 3 | 4/4 | OK | OK | OK | 0 | 7,806 | 41 / 9 | 81 / 73 | 25 / 0 |
| Total dos ensaios medidos | **12/12** | **3/3** | **3/3** | **3/3** | **0** | **8,459 média** | **125 / 29** | **243 / 219** | **74 / 1** |

Alvo e mínimo atingidos. As percentagens repetidas e as descidas referem-se aos frames observados durante o ensaio. O driver verificou a concordância da UI com o estado da API, snapshots recentes ou eventos aplicáveis nos pontos pontuados. A contagem de pedidos inclui navegação, recarregamento e reconexão. Estes números descrevem a sessão e não isolam custo de polling. Os registos, os vídeos e a tabela JSON estão em `evaluation/evidence/phase2-validation-2026-11-24/`.

## Observações de manutenção

| Área | Avaliação |
| --- | --- |
| Expansão do processamento | O padrão de consumidor concorrente permite acrescentar capacidade sem duplicar ferramentas, serviços ou contratos. O pipeline de cada vídeo continua num único job. A configuração medida tem duas réplicas fixas. |
| Extensão do estado | O modelo fica em `projects`, a validação de transições e o progresso têm módulos próprios e os gateways só transportam o contrato. A rota de snapshot serve página e painel. O painel mantém um projeto em destaque por separador, suficiente para o cenário especificado. |
| Complexidade | `projects/routes/projects.js` continua a concentrar etapas de orquestração e a chamada de reembolso cruza dois serviços. Os testes de concorrência protegem os caminhos alterados. Uma extração mais ampla mudaria código fora dos fluxos auditados. |
| Legibilidade do código | Durante a validação, o comentário de `persistAndSettleProcess` sugeria um único candidato ao commit e o avaliador repetia a atribuição do cabeçalho Authorization. Estes dois pontos foram tratados numa [sessão posterior](2026-11-24-clareza-finalizacao.md). |
| Reprodutibilidade do build | O `Dockerfile` do frontend já na base instalava dependências antes de copiar o lockfile, com Bun e imagem base por referências móveis. O build local usa uma imagem e dependências identificáveis nesta máquina. Um build externo pode resolver versões diferentes. [Dockerfile](../../frontend/Dockerfile) |
| Segurança de implantação | A configuração base conserva portas de serviços internos expostas, validação interna de TLS desativada e certificados e chaves de desenvolvimento versionados. Confirmei o Next.js 15.1.3 no contentor. A versão com App Router é abrangida pelo aviso crítico CVE-2025-66478. O nginx da stack dedicada publica a aplicação apenas em `127.0.0.1:8080`. A atualização de dependências e o isolamento dos serviços são condições para uma publicação real. [Auditoria F4](../fase-2-auditoria.md#3-falhas-e-pontos-críticos) · [Aviso oficial do Next.js](https://nextjs.org/blog/CVE-2025-66478) |
| Higiene Git | O diff do código de aplicação, testes e avaliador passa `git diff --check`. O diff histórico completo assinala espaços finais em ficheiros documentais e PDFs tratados como texto. A pasta de evidência permanece ignorada pelo Git. |

## QS-01 · Capacidade

- Um aquecimento completou os projetos A e B, mas o avaliador rejeitou a série porque o RabbitMQ dedicado não publica a gestão em `localhost:15672`. O run inválido `e2d36de9b24245feaf4b39d718f782ac` e as amostras ficaram guardados. Confirmei acesso autenticado ao endpoint de gestão pelo endereço interno do contentor e iniciei nova série sem mudar a configuração da aplicação.
- O diff dos componentes da aplicação entre `phase2-base` e o checkout `afb84e5` usado na baseline foi vazio. O protocolo conserva a diferença entre a série oficial de uma réplica, a comparação posterior de uma réplica com o instrumento revisto e a validação atual de duas réplicas. O arranque de B é comparável pela mesma definição temporal. As versões da máquina e do Docker, o estado da cache e as revisões do instrumento podem afetar tempos de conclusão e picos de recursos. [Comparação histórica](2026-11-23-espera-b.md)

| Ensaio | A (s) | B (s) | Espera B (s) | Lote (s) | Prontas máx. | Por confirmar máx. | CPU grupo (%) | RAM grupo (bytes) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 · `87a464ee4b9349a7873656ed71b98eee` | 92,503 | 10,419 | 0,175 | 92,503 | 2 | 2 | 818,620 | 4 386 235 350 |
| 2 · `0a322e81d3ab4938a61f5860ce40b334` | 92,442 | 10,352 | 0,113 | 92,442 | 2 | 2 | 750,420 | 4 389 456 576 |
| 3 · `b26f2b1ca5684b3fb65e4f683b83ba2d` | 92,493 | 10,377 | 0,139 | 92,493 | 2 | 2 | 766,440 | 4 383 014 124 |
| Média atual | **92,479** | **10,383** | **0,142** | **92,479** | **2** | **2** | **778,493** | **4 386 235 350** |
| Média final arquivada · duas réplicas | 80,961 | 9,676 | 0,113 | 80,961 | 2 | 2 | 738,700 | 4 288 882 758 |
| Média de comparação · uma réplica | 85,048 | 90,196 | 82,242 | 91,755 | 3 | 1 | 756,550 | 2 860 448 219 |
| Média oficial da base · uma réplica | 63,888 | 68,374 | 61,727 | 69,925 | 3 | 1 | 830,810 | 3 050 500 522 |

A espera atual de B ficou entre **0,113 e 0,175 s**, cumprindo o alvo de 15 s e o mínimo de 30 s. B terminou primeiro nos três ensaios. Cada ensaio teve um resultado para A e três para B, com IDs únicos no projeto e sem incidentes no ciclo de vida dos workers. O pico médio de RAM com duas réplicas foi 4,39 GB, face a 2,86 GB na comparação com o instrumento revisto. A duração média do lote nesta repetição foi 92,479 s, acima dos 80,961 s da série final arquivada. A repetição confirma a redução da espera de B. A variação entre séries limita a atribuição das diferenças de duração à arquitetura.

## Regressão com serviços reais

| Verificação | Resultado |
| --- | --- |
| Concorrência em MongoDB | 3/3. Progresso independente por vídeo e preservação de conclusão e falha perante edição com snapshot antigo. |
| Imagem PNG | 1 resultado descarregado por HTTP 200 e ZIP íntegro. |
| Vídeo MP4 + MOV | 2 resultados distintos descarregados por HTTP 200, convertidos para MP4/H.264, e ZIP íntegro. |
| Projeto misto | 1 imagem e 1 vídeo descarregados por HTTP 200, com ZIP íntegro. |
| Projeto misto com trim inválido | Estado `failed`, zero resultados publicados. |
| Extração de fotogramas | 3 PNG distintos da mesma origem, descarregados por HTTP 200, e ZIP íntegro. |
| Permissões da rota de estado pelo gateway | Dono 200, sem sessão 401, terceiro sem partilha 403, ligação de leitura 200, ligação de edição 200. |
| Quota e cancelamento | Apply concorrente 201/409 e cancel concorrente 204/409. Cancelamento repetido preservou o saldo e a execução partilhada reembolsou o pagador. |

Comandos usados. A pasta de evidência contém os logs e o script do teste integrado.

```sh
docker exec -i --workdir /app/tests picturas-validation-projects-1 node < projects/tests/project-concurrency.integration.js
PYTHONDONTWRITEBYTECODE=1 python3 evaluation/evidence/phase2-validation-2026-11-24/check_integrated.py
PYTHONDONTWRITEBYTECODE=1 python3 evaluation/check_video_quota_refund.py
```

## Build e validação local

- `node --check` passou nos ficheiros JavaScript alterados de orquestração, mensageria, quota e gateways. Os hashes da página e do painel do frontend em execução também coincidiram com a árvore local.
- Recompilei o frontend com `docker run --rm -e NEXT_TELEMETRY_DISABLED=1 picturas-validation-frontend:closeout` e `bun run build`, depois de mover a pasta `.next` existente dentro do contentor descartável. A compilação, a validação dos tipos e a geração de 13 páginas passaram. Há três avisos herdados de ESLint em ficheiros sem diff face à base. A tentativa inicial com `--network none` falhou ao obter as fontes Inter e Indie Flower de Google Fonts. Ambos os logs estão no pacote.
- Os primeiros ensaios QS-03 foram rejeitados na pré-condição de fila vazia logo após o ensaio de cancelamento. Nenhum serviço foi interrompido nessas tentativas. A nova série começou depois de confirmar `video_queue` com zero mensagens prontas, zero por confirmar e dois consumidores.

| Interrupção durante a legendagem | Estado final | Identidade e resultado | Fila e limpeza |
| --- | --- | --- | --- |
| Um worker | Passou | Mesma mensagem reentregue e mesma execução concluída. MP4 com vídeo e áudio e HTTP 200. | Dois consumidores recuperados, zero mensagens pendentes e zero novos temporários. |
| RabbitMQ | Passou | Mesma mensagem reentregue e mesma execução concluída. MP4 com vídeo e áudio e HTTP 200. | Dois consumidores de vídeo e um de projetos recuperados, zero mensagens de vídeo pendentes e zero novos temporários. |

Para repetir, executar sequencialmente `python3 evaluation/run_video_recovery.py --fault worker --output <ficheiro.json>` e o equivalente com `--fault broker`, com a fila vazia antes de cada ensaio. Os resultados válidos estão em `recovery-worker-idle.json` e `recovery-broker-idle.json`.

## Fecho

A revisão `fb18924` atingiu as metas dos dois requisitos não funcionais e passou os casos de preservação funcional exercitados. Pelos critérios da V1 local, o código está pronto para a revisão e entrega académica em ambiente controlado. A análise conserva os limites da comparação histórica, a dívida de implantação e as dependências externas do build. A grelha docente posterior, a reprodução por outro membro e a revisão do relatório e do registo de IA ficam com a equipa.

O código da aplicação e a fonte Typst ficaram intactos. Os CSV, logs, amostras, vídeos e scripts foram empacotados em `evaluation/evidence/picturas-phase2-validation-2026-11-24.tar.gz`, com verificação SHA-256. O D-01 histórico foi preservado. A stack dedicada ficou disponível em `127.0.0.1:8080` para a equipa.
