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

== Arrancar a aplicação

Num checkout do repositório indicado na introdução, usar Docker Engine e Docker Compose. A revisão `c2f4a3f` identifica o código com a correção da lista de efeitos em projetos partilhados. Os testes requerem Python 3.11 ou posterior com `requests`, acesso à CLI Docker e `ffprobe`. O ensaio de operabilidade usa Google Chrome e Playwright. O capítulo 2 e os manifestos dos arquivos registam as versões do ambiente de medição.

Na raiz do repositório, preparar checkouts separados para as três revisões usadas nos ensaios:

```sh
git worktree add ../picturas-baseline 0523102
git archive afb84e5 evaluation | tar -x -C ../picturas-baseline
git worktree add ../picturas-final 3cb1b74
git worktree add ../picturas-elasticity c2f4a3f
```

O instrumento de capacidade para a baseline vem de `afb84e5`; as revisões `3cb1b74` e `c2f4a3f` contêm, respetivamente, o instrumento final e o controlador de elasticidade. Instalar `requests` num ambiente Python 3.11 ou posterior em cada checkout. Para repetir o ensaio de navegador, instalar também Playwright 1.65.2 e disponibilizar Google Chrome em `/usr/bin/google-chrome`.

Abrir `https://localhost:8080`, aceitar o certificado local e iniciar sessão com uma conta Premium de teste. O vídeo longo de QS-01 excede o limite da conta Free. Para a execução ao vivo, exportar `PICTURAS_EMAIL`, `PICTURAS_PASSWORD` e `RABBITMQ_MANAGEMENT_PASSWORD` no terminal onde corre o instrumento. Usar uma pilha de ensaio com a fila inicialmente vazia e a cache do Whisper já aquecida.

== Repetir os cenários ao vivo

*QS-01.* Executar em sequência, numa pilha de ensaio por série. Na baseline, usar o checkout `../picturas-baseline`, com um worker e o instrumento de `afb84e5`. Na série final, usar `../picturas-final`, com dois workers fixos. Os três vídeos de entrada estão em `samples/video/`. O guia de reprodução descreve as configurações de armazenamento do arquivo D-01 e as diferenças face à campanha histórica.

```sh
# Baseline: um worker no Compose e o instrumento de afb84e5.
(cd ../picturas-baseline && docker compose up -d --build --scale video_tool=1)
(cd ../picturas-baseline && python3 evaluation/run_scenario.py \
  --runs 3 --warmup 1 --output-dir evaluation/evidence/replay-baseline)
(cd ../picturas-baseline && docker compose down)
# Série final: dois workers no Compose e o instrumento de 3cb1b74.
(cd ../picturas-final && docker compose up -d --build --scale video_tool=2)
(cd ../picturas-final && python3 evaluation/run_scenario.py \
  --runs 3 --warmup 1 --expected-workers 2 \
  --output-dir evaluation/evidence/replay-final)
(cd ../picturas-final && docker compose down)
```

#block(breakable: false)[
*QS-02.* Extrair o arquivo D-01 incluído no pacote final e copiar os respetivos dados para o checkout final:

```sh
cd evaluation/evidence
tar -xzf picturas-phase2-final-3cb1b74.tar.gz
tar -xzf phase2-final-3cb1b74/picturas-phase2-d01.tar.gz
cd ../..
mkdir -p ../picturas-final/evaluation/evidence
cp -a evaluation/evidence/picturas-phase2-d01/evaluation/evidence/. \
  ../picturas-final/evaluation/evidence/
```

Para a baseline em `0523102`, iniciar o checkout com uma réplica e seguir `observation-notes.md` em `evaluation/evidence/official-baseline-usability-2026-11-17/`, dentro de D-01, usando a amostra de fala do mesmo diretório. Para a série final em `3cb1b74`, iniciar o checkout com duas réplicas e executar o driver de D-01. O driver usa Chrome em `/usr/bin/google-chrome`, Playwright 1.65.2, uma janela de 1280 × 720 e uma sessão Premium.

```sh
(cd ../picturas-baseline && docker compose up -d --build \
  --scale video_tool=1)
# Seguir observation-notes.md e terminar a stack da baseline.
(cd ../picturas-baseline && docker compose down)
(cd ../picturas-final && docker compose up -d --build \
  --scale video_tool=2)
(cd ../picturas-final && PYTHONPATH=. \
  PICTURAS_U04_EVIDENCE=evaluation/evidence/replay-browser \
  python3 evaluation/evidence/u04-chromium-2026-11-22/browser_u04.py \
  warmup trial-1 trial-2 trial-3)
(cd ../picturas-final && docker compose down)
```
]

*Elasticidade.* No checkout `../picturas-elasticity`, arrancar com um worker. Executar `VIDEO_WORKERS_MAX=3 python3 scripts/autoscale_video.py` num terminal e o ensaio abaixo noutro. Para os controlos com réplicas fixas, parar o controlador antes de ajustar a escala no Compose.

```sh
# Iniciar a stack antes de lançar o controlador.
(cd ../picturas-elasticity && docker compose up -d --build \
  --scale video_tool=1)
# Terminal 1: manter o controlador em execução.
(cd ../picturas-elasticity && VIDEO_WORKERS_MAX=3 \
  python3 scripts/autoscale_video.py)
# Terminal 2: executar o ensaio.
(cd ../picturas-elasticity && python3 evaluation/run_scenario.py \
  --elastic --expected-workers 1 \
  --runs 3 --warmup 1 --process-timeout 240 \
  --output-dir evaluation/evidence/replay-elastic)
```

O `evaluation/phase2-reproduction.md` explica a preparação das entradas e a repetição em checkouts separados. A repetição da baseline usa uma imagem de worker reconstruída e o protocolo de navegador arquivado.

#pagebreak(weak: true)
== Recontar os registos arquivados

Os arquivos de evidência encontram-se em `evaluation/evidence/`. O pacote `picturas-phase2-final-3cb1b74.tar.gz` contém os manifestos, os dados da campanha final, os instrumentos e o arquivo original D-01, com as observações de base e amostras. A partir de `evaluation/evidence/`, executar:

```sh
sha256sum -c picturas-phase2-final-3cb1b74.tar.gz.sha256
tar -xzf picturas-phase2-final-3cb1b74.tar.gz
cd phase2-final-3cb1b74
sha256sum -c SHA256SUMS
python3 verify_final.py
```

A recontagem confirma 0,123429 s de espera média de B, 12/12 ações e 3/3 recuperações por navegação, recarregamento e reconexão. O arquivo `video-elasticity-2026-11-27.tar.gz`, também em `evaluation/evidence/`, reúne os controlos fixos e os ensaios com escala dinâmica. A partir de `evaluation/evidence/`, executar:

```sh
sha256sum -c video-elasticity-2026-11-27.tar.gz.sha256
tar -xzf video-elasticity-2026-11-27.tar.gz
cd video-elasticity-2026-11-27
sha256sum -c SHA256SUMS
python3 instruments/summarize.py dynamic --runs 3
```

A recontagem confirma a média de 7,902 s nos três ensaios válidos. Estes comandos recontam observações arquivadas; não repetem os ensaios no sistema.

== Repetição independente

A reprodução independente deve ser feita numa stack separada e registada para a entrega. O documento `evaluation/phase2-reproduction.md` descreve o ambiente, as versões, as entradas e os comandos necessários. Para evitar confundir dados arquivados com novas medições, cada membro deve guardar uma cópia dos logs, o resultado dos checksums, a versão Git testada e as ações individuais por ensaio.

Os resultados desta reprodução independente não substituem, nem reescrevem, os valores das campanhas já arquivadas. Qualquer diferença deve ser apresentada como observação nova, com ambiente e método comparável documentados.

= Glossário

#tabela(
  colunas: (4cm, 1fr),
  tamanho: 8.5pt,
  [Termo], [Definição],
  [QS], [Cenário de qualidade: descreve o estímulo, o ambiente e uma resposta mensurável. `QS-01` é o cenário de capacidade, `QS-02` o de operabilidade e `QS-03` o de recuperação.],
  [CAND], [Candidato a requisito não funcional do Bloco 2; ao ser escolhido, o seu cenário passou a designar-se `QS-nn`.],
  [DA], [Decisão arquitetural associada a um cenário (`DA-1` réplicas de vídeo, `DA-2` estado persistido e recuperação da interface).],
  [TAT], [Tática candidata de desenho, classificada como _refactoring_ puro (A), alteração visível que é o objeto da melhoria (B) ou funcionalidade nova (C, rejeitada).],
  [ALT], [Alternativa arquitetural avaliada no diagnóstico e retomada nas decisões (e.g., `ALT-3`, separação por perfil de carga).],
  [EV], [Evidência: um facto sobre o código ou o comportamento, com fonte citada (ficheiro e linhas numa revisão).],
  [H], [Hipótese: afirmação sem evidência executada, mantida marcada até ser confirmada ou refutada.],
  [P-n], [Incremento de desempenho da implementação (e.g., `P-02`, segurança de resultados em lotes concorrentes).],
  [U-n], [Incremento de usabilidade da implementação (e.g., `U-04`, interface recuperável).],
  [R-n], [Passo da regressão integral: orquestração, _worker_, frontend integrado e instrumento de medição.],
  [M-n], [Meta de medição comparativa antes/depois (e.g., espera média de B, ações de usabilidade).],
  [F-n], [Correção de seguimento: falha detetada durante a validação e reparada num incremento próprio (e.g., `F8`, reembolso da quota ao cancelar).],
  [D-n], [Entregável documental: `D-01` é o arquivo de evidência reprodutível e `D-02` o relatório final.],
  [B-n], [_Gate_ de auditoria: ponto de controlo do plano de implementação com critério de fecho registado.],
  [Baseline], [Medição inicial antes do _refactoring_, obtida com o mesmo método, ambiente e entradas usados na medição final.],
  [Cenário A/B], [Configuração de carga em que o utilizador A submete um trabalho longo e o utilizador B interage ou submete durante o seu processamento.],
  [Espera de B], [Intervalo entre o pedido de B e o primeiro arranque de trabalho de vídeo registado pelo _worker_; métrica central de `QS-01`.],
  [Lote], [Conjunto de processamentos disparados por uma só aplicação do _pipeline_ do projeto a todos os media elegíveis.],
  [Pipeline], [Sequência ordenada de efeitos associada ao projeto (não a cada item), aplicada em lote a imagens e vídeos.],
  [Worker], [Consumidor de fila que executa efeitos: os serviços de ferramentas de imagem e o `video_tool`.],
  [Réplica], [Instância de um serviço _worker_ a correr em paralelo no Compose; a espera de B diminui com o número de réplicas de `video_tool`.],
  [_Prefetch count_], [Número de mensagens AMQP que um consumidor aceita sem confirmar; `video_tool` usa 1 para permitir distribuição justa entre réplicas.],
  [Reentrega], [Nova entrega pelo RabbitMQ de uma resposta já tratada após interrupção do orquestrador; a gravação de resultados é idempotente, pelo que não duplica resultados.],
  [Token da execução], [Identificador que valida que um evento ou resultado pertence à execução ativa do lote, protegendo contra _reentregas_ e eventos fora de ordem.],
  [`processingRun`], [Documento do MongoDB com o estado persistido da execução de um lote, do qual a interface recupera o acompanhamento.],
  [_Snapshot_], [Estado persistido da execução, usado para recuperar o acompanhamento após navegação, recarregamento ou reconexão.],
  [_Preview_], [Renderização parcial (primeiros 3 s) publicada durante o processamento para acompanhamento rápido na interface.],
  [Escala automática], [Controlador opcional que consulta a fila `video_queue` e ajusta o número de réplicas de `video_tool` no Compose, reduzindo a escala apenas após inatividade observada.],
  [Saída graciosa], [Encerramento de uma réplica (`SIGUSR1`) que conclui e confirma o trabalho em curso antes de sair, usado na redução da escala.],
  [`image_data`], [Volume Docker partilhado onde os serviços leem as entradas e escrevem os resultados de imagem e vídeo.],
  [`FREE_DAILY_OP`], [Quota diária de operações da conta _free_ (5); cada efeito aplicado consome uma operação.],
)
