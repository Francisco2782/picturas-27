# Relatório Explicativo do Projeto PictuRAS (Fase 2)

---

## 1. Resumo de Uma Página

O PictuRAS é uma plataforma web em microserviços Docker para edição em lote de imagens e vídeos, organizada em projetos onde os utilizadores aplicam uma sequência ordenada de efeitos (pipeline).
Na presente Fase 2 da unidade curricular de Requisitos e Arquiteturas de Software (RAS), a equipa tem como missão melhorar dois Requisitos Não Funcionais (RNF) através de refactoring arquitetural, sem adicionar novas funcionalidades aos utilizadores.
Os dois requisitos escolhidos foram a Eficiência de Desempenho (Capacidade de processamento de vídeo) e a Usabilidade (Operabilidade da interface durante o processamento).

O código da aplicação validado é `3cb1b74`. A configuração medida usa dois trabalhadores de vídeo na mesma fila, com um trabalho por réplica. O Compose mantém uma réplica por omissão. A interface usa o estado persistido em MongoDB e um painel que permite continuar a navegar durante o processamento.

- **QS-01 · Capacidade.** A espera média do projeto B caiu de **61,727 s** na linha de base para **0,123 s** em três ensaios válidos, face a um alvo de **≤ 15 s**. B terminou antes de A nos três ensaios. O pico de RAM agregado foi superior ao da comparação com uma réplica.
- **QS-02 · Operabilidade.** No Chromium, o resultado passou de **6/12** para **12/12 ações**. A revisão final recuperou o estado em **3/3 ensaios por tipo** de navegação, recarregamento e reconexão, com zero conclusões prematuras. [Validação final](sessoes/2026-11-24-validacao-final-3cb1b74.md)

As regressões cobrem o fecho simultâneo de vídeos, edições concorrentes, progresso independente por vídeo, permissões, cancelamento e devolução da quota. A última correção tornou a gravação de resultados idempotente perante reentrega da resposta. Passaram 38 testes de Node, 14 do avaliador, cinco em MongoDB e os cenários de imagem, vídeo, lote misto e extração de fotogramas pela API. [Reentrega e regressões](sessoes/2026-11-24-reentrega-resultados.md)

O pacote final reúne os dados brutos, o manifesto, os instrumentos e a baseline original. A extração limpa confirmou os hashes e reproduziu as tabelas. O relatório Typst está redigido em rascunho. Faltam a revisão humana e o registo da reprodução por outro membro da equipa. [Guia de reprodução](../evaluation/phase2-reproduction.md) · [Fonte do relatório](src-doc-fase2-template/README.md)

---

## 2. O Que É Suposto Esta Fase Fazer

### 2.1 Objetivo da Fase 2
O objetivo pedagógico e técnico da Fase 2 consiste em aplicar engenharia de software rigorosa para transformar uma aplicação funcional tipo MVP (Produto Mínimo Viável, uma versão inicial simplificada criada apenas para validar conceitos) numa solução robusta quanto a atributos de qualidade não funcionais.
A regra fundamental imposta pelo corpo docente é que é estritamente proibido criar novas funcionalidades para o utilizador final (por exemplo, novos filtros ou botões de edição). Todo o esforço de engenharia deve seguir o ciclo obrigatório:
1. Identificação e caracterização de 2 Requisitos Não Funcionais (RNF) distintos, classificados segundo a norma internacional ISO/IEC 25010:2011;
2. Medição empírica de uma linha de base (*baseline*, que representa o estado e desempenho do sistema original antes de qualquer alteração de código);
3. Conceção e implementação de táticas arquiteturais através de refactoring (reestruturação interna do código sem alterar o comportamento externo visível);
4. Medição final nas mesmas condições experimentais da linha de base, comprovando quantitativamente a melhoria obtida e avaliando os compromissos (*trade-offs*, isto é, ganhos num atributo versus custos noutro).

### 2.2 Entregáveis Exigidos
A V1 descreve o trabalho e remete o formato de entrega para uma revisão posterior. A equipa preparou estes materiais. [Diretrizes da Fase 2](fase-2-guidelines.md)

1. **Relatório Técnico da Fase 2** em Typst, compilável para PDF e organizado em cinco partes:
   - Parte I: Introdução e Âmbito da Arquitetura (enquadramento e vista factual herdada da Fase 1);
   - Parte II: Diagnóstico Arquitetural (Exercício 6 Bloco 1, com identificação de padrões, forças, fraquezas e alternativas arquiteturais);
   - Parte III: Qualidade e Requisitos Não Funcionais (Exercício 6 Bloco 2, com cenários de qualidade quantificados segundo a norma ISO/IEC 25010 e matriz de compromissos);
   - Parte IV: Táticas, Decisões, Medição e Resultados (Exercício 7, com formulação de decisões arquiteturais, medições antes/depois e preservação funcional);
   - Parte V: Síntese e Utilização de Inteligência Artificial (conclusões e documentação detalhada das ferramentas de IA usadas, tarefas apoiadas, erros da IA e validações humanas realizadas).
2. **Repositório de Código Fonte**: código com o refactoring implementado, acompanhado por testes automatizados (testes unitários e testes de integração que asseguram que a aplicação continua a funcionar sem regressões funcionais).
3. **Evidências Experimentais e Scripts de Avaliação** com registos de execução, manifestos das imagens Docker e dados brutos para recalcular as métricas e repetir os cenários.

### 2.3 Critérios de Avaliação
A avaliação da Fase 2 assenta em cinco pilares fundamentais:
- **Rastreabilidade e Rigor Factual**: cada afirmação sobre o sistema deve estar ancorada em evidências do código (`EV-nn`) ou ser explicitamente marcada como hipótese a validar (`H-nn`).
- **Isolamento de Variáveis e Reprodutibilidade**: as medições da linha de base e da solução final têm de usar o mesmo hardware, os mesmos ficheiros de vídeo de teste e a mesma ferramenta de recolha de métricas.
- **Preservação Funcional**: demonstração inequívoca de que nenhum pipeline de imagem ou vídeo foi quebrado (regras de formatos, codecs, orquestração e autorizações de acesso mantêm-se íntegras).
- **Análise Crítica de Compromissos**: demonstrar que a equipa compreende o custo de cada melhoria (por exemplo, duplicar réplicas reduz o tempo de espera mas consome mais memória RAM e percentagem de processador CPU).
- **Transparência no Uso de Ferramentas de IA**: prestação de contas explícita sobre como ferramentas como Claude Code, Cursor ou GitHub Copilot foram usadas, evidenciando o código gerado, os defeitos introduzidos pela IA que foram detetados em testes e as decisões rejeitadas pelos membros humanos da equipa.

### 2.4 Prazos Oficiais e Estado Administrativo
- **Data de Submissão no Enunciado Original**: 20 de novembro de 2026 (`docs/fase-2-guidelines.md`, página 1).
- **Período de Defesas Presenciais**: 23 a 27 de novembro de 2026.
- **Prazo comunicado pela equipa**: 27 de novembro de 2026. O dia 20 acima corresponde à versão inicial das diretrizes.

---

## 3. Cronologia do Trabalho Realizado

O trabalho da Fase 2 foi executado de forma estritamente sequencial, dividindo-se em fases de diagnóstico, captura de dados prévios, implementação de táticas, auditoria interna e validação integrada final. A ordem adotada obedeceu à regra de nunca alterar código antes de ter uma linha de base medida e congelada.

```
[B-01 a B-04] Captura da Linha de Base (Baseline Oficial)
        │
        ▼
[P-01] Escalação de Réplicas do Trabalhador de Vídeo
        │
        ▼
[P-02 e P-03] Mecanismos de Concorrência e Gestão de Recursos do Vídeo
        │
        ▼
[U-01 a U-03] Persistência de Estado e Consulta Autorizada de Execuções
        │
        ▼
[U-04] Interface Não Bloqueante e Reconciliação no Dashboard
        │
        ▼
[Auditoria Interna de 21/11] Deteção das Falhas Críticas F1 (Concorrência) e F5 (Navegador)
        │
        ▼
[Correção e Prova Integrada] Resolução de F1 (commit 7757555) e de F5 (sessão de 22/11)
        │
        ▼
[M-01 a M-04] Ensaios Finais de Desempenho e Usabilidade com Sucesso
        │
        ▼
[23/11] Recuperação de vídeo, polling, quotas e concorrência no estado
        │
        ▼
[24/11] Reentrega sem duplicação e repetição de QS-01/QS-02 em 3cb1b74
```

1. **Gate Oficial da Linha de Base (Tarefas B-01 a B-04) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* O enunciado docente proíbe tocar no código da aplicação antes de registar o desempenho do sistema original.
   - *O que se fez:* Adaptou-se a ferramenta de avaliação (`evaluation/run_scenario.py` e `evaluation/summarize.py`) para recolher métricas agregadas de múltiplos contentores Docker (B-01). No dia 17 de novembro de 2026, sobre o commit original `0523102` (tag `phase2-base`), mediram-se a linha de base de capacidade (B-02) e a linha de base de usabilidade (B-03), sendo os resultados aprovados formalmente na reunião de equipa B-04 (`specs/002-nfr-improvement/tasks.md#L14-L65`).
2. **Tática de Capacidade (Tarefas P-01 a P-03) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* A capacidade do processamento de vídeo era o estrangulamento mais pesado do backend, afetando diretamente a arquitetura de microserviços.
   - *O que se fez:* Em P-01 iniciaram-se 2 réplicas do contentor `video_tool` a consumir da mesma fila RabbitMQ com limite de 1 trabalho por réplica (`prefetch_count=1`). Em P-02 reestruturou-se a orquestração em `projects` para registar barreiras de processos antes do despacho. Em P-03 verificou-se a libertação de ficheiros temporários `.part` e a persistência de modelos em cache de disco (`docs/fase-2-implementacao.md#L64-L166`).
3. **Tática de Operabilidade (Tarefas U-01 a U-04) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* Para permitir que o utilizador continue a interagir com a interface enquanto um vídeo processa, o backend tem de guardar o estado no MongoDB para que o frontend o consiga consultar após qualquer navegação.
   - *O que se fez:* Em U-01 criou-se o modelo persistente `processingRun` no MongoDB. Em U-02 ligou-se o envio de percentagens do trabalhador de vídeo para o orquestrador via RabbitMQ. Em U-03 disponibilizou-se a rota autorizada `GET /api-gateway/projects/:user/:project/processing-status`. Em U-04 substituiu-se a janela modal bloqueante pelo painel de estado do dashboard. [Registo de implementação](fase-2-implementacao.md)
4. **Auditoria de Qualidade e Descoberta de Falhas (21 de novembro de 2026) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* Antes de declarar a Fase 2 como concluída, realizou-se uma auditoria minuciosa ao código e aos testes integrados para garantir que não existiam efeitos secundários escondidos.
   - *O que se fez:* Descobriram-se 9 pontos críticos (de F1 a F9, descritos em `docs/fase-2-auditoria.md`). O mais gravoso era o defeito F1: quando dois vídeos do mesmo projeto terminavam no mesmo milissegundo em trabalhadores diferentes, a rotina de limpeza apagava todos os ficheiros resultantes do armazenamento S3, deixando o projeto concluído mas vazio.
5. **Correção de F1, Resolução de F5 e Regressão Integrada (22 de novembro de 2026) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* Era imperativo corrigir a perda de resultados e os problemas de interface antes de realizar as medições definitivas.
   - *O que se fez:* No commit `7757555` corrigiu-se F1 em `projects/routes/projects.js:discardRunResults`. Em F5 blindou-se a interface contra recarregamentos acidentais de página (F5) e perda de permissões de partilha. Em seguida, executou-se a bateria de testes integrados e a campanha de medição final (`docs/sessoes/2026-11-22-fecho-fase-2.md`).
6. **Seguimento de fiabilidade e concorrência (23 de novembro de 2026).** O QS-03 confirmou a recuperação após interrupção do worker e do broker. Um ensaio separado mediu o custo HTTP de um observador a 1 Hz. Corrigiram-se o reembolso ao pagador original (F8), as escritas que podiam repor estado antigo numa edição (F2) e a ordenação de progresso por vídeo (F3). [Recuperação e polling](sessoes/2026-11-23-recuperacao-e-polling.md) · [Quotas](sessoes/2026-11-23-commits-fase2.md) · [F2 e F3](sessoes/2026-11-23-f2-f3.md)
7. **Reentrega e validação da revisão final (24 de novembro de 2026).** A campanha em `fb18924` confirmou os dois alvos. Em `3cb1b74` corrigiu-se a duplicação perante reentrega de respostas já gravadas e repetiram-se as duas campanhas completas. O registo, as tabelas e as instruções foram publicados em `f89b220`. [Reentrega](sessoes/2026-11-24-reentrega-resultados.md) · [Validação final](sessoes/2026-11-24-validacao-final-3cb1b74.md)

---

## 4. Explicação Detalhada do Projeto PictuRAS (Fase 2)

### 4.1 O Que Faz a Aplicação (A Perspetiva do Utilizador)
O PictuRAS é uma aplicação web para edição multimédia. O utilizador cria um **projeto** e carrega imagens (por exemplo, PNG e JPEG). Os perfis gratuito e premium também podem carregar vídeo (MP4, MOV ou WebM, sujeito aos limites de formato e de perfil). O perfil anónimo tem acesso limitado à edição de imagem.
No PictuRAS, os efeitos de edição não são aplicados individualmente a cada foto ou vídeo de forma isolada; o utilizador constrói um **pipeline** (uma cadeia sequencial de operações, por exemplo: rodar 90 graus, aumentar o brilho em 20% e adicionar legendas automáticas). Quando o utilizador clica no botão "Apply", o sistema processa em lote todos os media que pertencem a esse projeto aplicando a mesma sequência de efeitos.
Os utilizadores com plano gratuito dispõem de uma quota diária de 5 operações (`FREE_DAILY_OP = 5`), enquanto os utilizadores premium têm processamento ilimitado e autorização para carregar vídeos maiores (até 600 segundos e 1 GB, contra 60 segundos e 100 MB no plano gratuito).

### 4.2 Arquitetura do Sistema e o Caminho de um Pedido
A aplicação é composta por um conjunto de serviços independentes que comunicam entre si em rede, orquestrados através de contentores Docker definidos no ficheiro `docker-compose.yaml`:

```
[Navegador do Utilizador]
        │ HTTPS (Porta 8080)
        ▼
   [Servidor Nginx (Proxy Reverso)]
   ┌────┴───────────────────────────┬───────────────────────────┐
   │ / (Frontend Next.js)           │ /api-gateway/ (Express)   │ /socket.io (WebSocket)
   ▼                                ▼                           ▼
[Frontend UI]                 [API Gateway]               [WS Gateway]
                              (Valida JWT)                (Eventos em tempo real)
                                    │
                       ┌────────────┴────────────┐
                       ▼                         ▼
               [Serviço Users]           [Serviço Projects]
               (Contas e Quotas)         (Orquestrador do Trabalho)
                                                 │
                          ┌──────────────────────┼──────────────────────┐
                          ▼                      ▼                      ▼
                  [Base MongoDB]       [Storage SeaweedFS]     [RabbitMQ Broker]
                  (Metadados)          (Ficheiros S3)          (Filas de Mensagens)
                                                                        │
                                                ┌───────────────────────┴───────────────────────┐
                                                ▼                                               ▼
                                      [Trabalhadores Imagem]                          [Trabalhadores Vídeo]
                                      (binarization, cut, ...)                        (video_tool: 1 por omissão,
                                                                                       2 no ensaio de capacidade)
```

- **Nginx.** O acesso normal da aplicação é por HTTPS na porta 8080. O nginx encaminha `/` para o frontend em Next.js, `/api-gateway/` para a API Express, `/socket.io` para o gateway de eventos e `/s3/` para SeaweedFS. Internamente, `imageStorageService` faz a mediação entre `projects` e o armazenamento S3.
- **Serviço de Utilizadores (`users`).** Gere contas, emite tokens JWT assinados e controla o saldo de operações diárias em MongoDB.
- **Serviço de Projetos (`projects`)**: Atua como o cérebro orquestrador. Guarda no MongoDB a lista de projetos, os ficheiros associados, as ferramentas configuradas e o estado de execução.
- **Fila de Mensagens (RabbitMQ)**: Um intermediário de mensageria assíncrona (*message broker*) que gere filas de tarefas. Os pedidos não bloqueiam os servidores web: são colocados em filas e retirados pelos trabalhadores.
- **Trabalhadores de Imagem (`Tools/<tool>/`).** Microsserviços que recebem um passo do pipeline por imagem, como brilho, corte, rotação ou um filtro de IA.
- **Trabalhadores de Vídeo (`Tools/video/`, serviço `video_tool`)**: Microsserviço Python especializado em vídeo. Ao contrário das imagens, um vídeo não é decomposto em mensagens separadas por cada filtro: o orquestrador envia uma única mensagem com o pipeline completo para a fila `video_queue`. O trabalhador lê o ficheiro de vídeo, descodifica com a biblioteca multimédia `ffmpeg`, aplica os filtros de fotogramas de forma combinada em memória, processa áudio se necessário, transcreve fala com o modelo Faster-Whisper, codifica o ficheiro final em formato MP4 (com codec de vídeo H.264 e áudio AAC) e devolve a resposta na fila `project_queue`.

#### O Caminho de um Pedido de Vídeo Passo a Passo:
1. O utilizador clica no botão "Apply" na interface web.
2. O navegador envia um pedido HTTP `POST /api-gateway/projects/:user/:project/process` com o token JWT de autenticação no cabeçalho.
3. O `apiGateway` verifica a validade da assinatura do token JWT e reencaminha o pedido internamente para o serviço `projects`.
4. O serviço `projects` consulta o serviço `users` para debitar as operações da quota do utilizador. Em seguida, gera um identificador numérico de execução (`runToken`, por exemplo `runToken = 4`), cria os registos de barreira na coleção `Process` do MongoDB e envia uma mensagem JSON para a fila `video_queue` do RabbitMQ contendo o identificador do ficheiro e a lista de efeitos.
5. Uma das réplicas disponíveis do serviço `video_tool` retira a mensagem da fila `video_queue` (pois tem `prefetch_count=1`, aceitando apenas 1 vídeo de cada vez).
6. O trabalhador de vídeo faz o download do ficheiro original a partir do volume partilhado `image_data`, processa os fotogramas com ffmpeg, transcreve o áudio com Faster-Whisper (se o efeito `subtitles` estiver configurado) e grava o resultado num ficheiro temporário com a extensão `.part`. À medida que atinge marcos no processamento (e.g., 25%, 50%, 75%), o trabalhador envia mensagens de progresso para a fila `project_queue`.
7. O serviço `projects` consome essas mensagens de progresso da `project_queue`, valida que pertencem à execução ativa, atualiza o documento do projeto em MongoDB e reencaminha o evento para a fila `ws_queue`. O `wsGateway` recebe o evento e transmite-o por WebSocket para a interface do navegador, que atualiza a barra de progresso visual.
8. Ao terminar a codificação, o trabalhador de vídeo publica o ficheiro definitivo. Envia uma resposta persistente para `project_queue` e só confirma o trabalho original depois de o RabbitMQ confirmar a publicação da resposta.
9. O serviço `projects` carrega a saída para o armazenamento e regista-a no MongoDB. Se a resposta for repetida, reutiliza a saída que já tem a chave do trabalho e da posição na resposta. O registo `Process` mantém o trabalho pendente até as saídas estarem gravadas. Quando o lote fica sem pendências, uma atualização condicional confirma a execução e o cliente pode consultar os resultados.

---

### 4.3 Os Dois Requisitos Não Funcionais Escolhidos

A equipa selecionou dois atributos de qualidade de acordo com a norma internacional **ISO/IEC 25010:2011**, que define um modelo padrão para avaliar a qualidade de software:

```
Requisitos Não Funcionais Escolhidos
├── 1. Eficiência de Desempenho / Capacidade (ISO/IEC 25010 §4.2.2)
│      └── Problema: Fila única de vídeo bloqueada por legendas longas em CPU
│      └── Métrica: b_wait_seconds (tempo até o segundo projeto conseguir começar)
│      └── Baseline Oficial: 61,727 segundos ──► Meta Final: ≤ 15 segundos
│
└── 2. Usabilidade / Operabilidade (ISO/IEC 25010 §4.3.5)
       └── Problema: Ecrã bloqueado por janela modal cinzenta e perda de estado com F5
       └── Métrica: Ações concluídas em B (0–4) e taxa de recuperação de estado (0–3)
       └── Baseline Oficial: 6/12 ações (50%) ──► Meta Final: 12/12 ações (100%)
```

#### Requisito 1: Eficiência de Desempenho — Subcaracterística: Capacidade
- **Porquê este requisito:** Na versão herdada da Fase 1, existia apenas um único trabalhador de vídeo (`video_tool`), que só conseguia processar um vídeo de cada vez. Quando um utilizador submetia um vídeo com legendagem automática (uma tarefa computacionalmente pesada que corre sobre o processador da máquina usando o modelo de inteligência artificial Faster-Whisper), o trabalhador ficava monopolizado durante dezenas de segundos ou minutos. Se outro utilizador submetesse um projeto simples com vídeos curtos logo a seguir, esses vídeos ficavam presos na fila à espera que a transcrição do primeiro terminasse.
- **Caso de Uso de Teste:** O utilizador A submete um projeto com um vídeo de fala de 177 segundos com o efeito `subtitles`. Um segundo e meio depois, o utilizador B submete um projeto com dois vídeos MP4 de 10 segundos e um vídeo MOV de 6 segundos com um efeito simples de brilho (`brightness`).
- **Métrica Medida:** `b_wait_seconds`, o intervalo entre a submissão de B e o primeiro registo de início de brilho de B nos logs das réplicas.
- **Linha de Base (*Baseline*) Medida:** Média oficial de **61,727 segundos** (com mínimo de 61,390 s e máximo de 61,936 s nos três ensaios válidos, conforme `evaluation/evidence/official-baseline-performance-2026-11-17/`).
- **Meta Definida:** Média final de `b_wait_seconds` menor ou igual a **15 segundos** (mínimo aceitável: menor ou igual a 30 segundos).

#### Requisito 2: Usabilidade — Subcaracterística: Operabilidade
- **Porquê este requisito:** Na versão herdada, quando o utilizador clicava em "Apply", o frontend React ativava uma camada cinzenta semitransparente em todo o ecrã (*overlay modal bloqueante*) com uma animação de carregamento. O utilizador ficava impedido de clicar em qualquer menu ou abrir outro projeto enquanto o lote estivesse a processar. Pior ainda: o estado do progresso estava guardado exclusivamente na memória efémera daquele componente React. Se o utilizador mudasse de página na barra de endereços ou pressionasse a tecla F5 para recarregar a página, a interface perdia a ligação com o processo em curso, apresentando o projeto como se nada estivesse a acontecer ou forçando uma falsa conclusão.
- **Caso de Uso de Teste:** O utilizador inicia o processamento de legendas num projeto A (vídeo de 10 segundos). Enquanto o projeto A está a processar ativamente, o utilizador tenta realizar 4 ações: (1) abrir a página do projeto B, (2) interagir com a barra de ferramentas do projeto B, (3) regressar à página do projeto A e (4) confirmar visualmente que o estado do projeto A continua a avançar corretamente. Em seguida, testa-se o recarregamento da página (F5) e o corte temporário da ligação de rede.
- **Métrica Medida:** Número de ações interativas concluídas com sucesso durante o processamento ativo (escala de 0 a 4 por ensaio, totalizando 12 ações em três ensaios) e a taxa de recuperação bem-sucedida do estado após navegação (0 a 3) e após recarregamento F5 (0 a 3), com tolerância zero para conclusões prematuras.
- **Linha de Base (*Baseline*) Medida:** Na linha de base oficial (`phase2-base`), conseguiram-se apenas **6 em 12 ações** (50% de sucesso). As ações de voltar ao projeto A e confirmar o estado falharam em 100% das tentativas (0/3), e a recuperação após navegação ou refresh foi de **0 em 3**, ficando o ecrã congelado ou desincronizado.
- **Meta Definida:** **12 em 12 ações** concluídas com sucesso (100%), recuperação após navegação em **3 de 3 ensaios**, recuperação após refresh em **3 de 3 ensaios**, e **zero conclusões falsas ou prematuras**.

---

### 4.4 Cada Tática e Melhoria Implementada (P-01 a P-03 e U-01 a U-04)

#### Incremento P-01 — Escalação Controlada de Réplicas de Vídeo em Docker Compose
`[FEITO E VERIFICADO]`

1. **O que era o problema:** Existia apenas uma réplica do trabalhador de vídeo ligada à fila `video_queue`. Todas as mensagens eram processadas em fila indiana estrita por esse único processo.
2. **O que acontecia antes:** Quando o projeto A enviava um vídeo com legendagem demorada e o projeto B enviava vídeos curtos, o trabalhador ficava ocupado com A. O projeto B ficava retido na fila do RabbitMQ sem que ninguém lhe tocasse durante mais de um minuto.
3. **O que acontece agora:** Quando A ocupa uma réplica, a outra pode começar B. Nos três ensaios medidos da revisão final, B começou menos de 0,14 s após a sua submissão.
4. **Porque foi feito assim:** Optou-se por escalar réplicas independentes consumindo da mesma fila existente em vez de criar filas separadas com prioridades ou reescrever o trabalhador com multithreading complexo em Python. Cada réplica mantém `prefetch_count=1`, garantindo que nenhuma réplica acumula trabalhos em excesso na sua memória.
5. **Onde está no código:** A escala do ensaio usa `docker compose up -d --scale video_tool=2`. O consumidor chama `basic_qos(prefetch_count=1)` em `Tools/video/video.py`.
- **Exemplo concreto:** O avaliador submeteu B 1,5 s depois de A. No primeiro ensaio medido da revisão final, uma réplica iniciou B 0,112955 s após a sua submissão, enquanto A ainda processava. [Registos por ensaio](sessoes/2026-11-24-validacao-final-3cb1b74.md)
- **Como foi testado:** Smoke test documentado em `evaluation/evidence/phase2-p01-smoke-2026-11-17/`, onde o comando `rabbitmqctl list_queues name consumers` confirmou exatamente 2 consumidores na fila `video_queue`.

---

#### Incremento P-02 — Preservação de Resultados em Finalizações Concorrentes
`[FEITO E VERIFICADO]`

1. **O que era o problema:** Quando dois vídeos do mesmo projeto eram processados em paralelo por dois trabalhadores diferentes e terminavam no mesmo instante, existia uma condição de corrida (*race condition*) no orquestrador.
2. **O que acontecia antes:** Os dois trabalhadores concluíam os respetivos vídeos e enviavam a mensagem para o orquestrador em `projects/utils/processBatch.js`. Ambos removiam o seu registo `Process` do MongoDB e consultavam `countPending`. Ambos viam 0 tarefas pendentes. O primeiro a chegar fazia o commit do lote e marcava o estado como `completed`. O segundo recebia resposta de commit nulo (`committed = false`). Como `committed` era falso, o código invocava `cleanupStale(process)`. Em `projects/routes/projects.js`, a função `discardRunResults` apagava do MongoDB e do armazenamento S3 todos os ficheiros daquele token, incluindo os ficheiros acabados de guardar pelo primeiro trabalhador! O lote ficava marcado como sucesso, mas com **zero resultados**.
3. **O que acontece agora:** Quando o segundo trabalhador vê que o commit falhou e tenta limpar tarefas obsoletas, a função `discardRunResults` consulta primeiro o documento do projeto no MongoDB. Se o token pertencer à execução que está atualmente confirmada (`committedToken === token`) ou se for o token reservado para recuperação (*rollback*), a limpeza é imediatamente abortada e retorna `null`. Os ficheiros de ambos os vídeos são protegidos e preservados intactos.
4. **Porque foi feito assim:** Foi feita uma verificação de segurança no ponto central de eliminação de ficheiros (`discardRunResults`). Em vez de confiar cegamente na ordem de chegada das mensagens assíncronas do RabbitMQ, a base de dados do MongoDB funciona como árbitro de verdade.
5. **Onde está no código:** Em `projects/routes/projects.js`, função `discardRunResults` (linhas 173–182 no commit `7757555`), e na função de barreira em `projects/utils/processBatch.js:persistAndSettleProcess` (linhas 20–40).
- **Exemplo concreto:** A regressão `simultaneous completion preserves both video results` força duas conclusões a observar zero trabalhos pendentes. O teste, com serviços simulados, exige duas saídas preservadas e uma confirmação do lote. A prova integrada verificou os resultados descarregáveis com os serviços reais.
- **Como foi testado:** Teste unitário em `projects/tests/process-batch.test.js` e validação integrada documentada na sessão `docs/sessoes/2026-11-22-p02.md`, executada contra uma base MongoDB real com o profiler ativado, confirmando 2 ficheiros no ZIP gerado.

---

#### Incremento P-03 — Gestão de Recursos e Limpeza do Trabalhador de Vídeo
`[FEITO E VERIFICADO]`

1. **O que era o problema:** O processamento de vídeo cria ficheiros pesados em disco. Em caso de falha de energia, reinício de contentor ou erro de codificação, ficheiros temporários corrompidos podiam ficar esquecidos a encher o disco partilhado.
2. **Ponto de partida:** A base já escrevia a saída de vídeo em temporários. Com duas réplicas, tornou-se necessário verificar a limpeza e a recuperação em falhas durante a execução.
3. **O que acontece agora:** O trabalhador prepara a saída em ficheiros como `encoded.part.mp4` e só substitui o ficheiro final após a codificação. A tentativa seguinte limpa os artefactos abandonados da mesma saída. O volume `whisper_models` permite às réplicas reutilizar os modelos descarregados.
4. **Porque foi feito assim:** A substituição atómica evita expor uma saída parcialmente escrita. O volume de modelos reduz os downloads repetidos.
5. **Onde está no código:** O processamento e a substituição atómica estão em `Tools/video/video_processor.py`. Os testes do processador estão em `Tools/video/tests/test_video_processor.py`.
- **Exemplo concreto:** P-03 mediu um pico de **271,6% de CPU** e **1,85 GiB de RAM** num vídeo de 60 s com brilho e verificou o regresso dos consumidores após reiniciar RabbitMQ. No seguimento QS-03, um trabalho de legendagem ativo retomou após reiniciar o worker ou o broker, ficou descarregável e deixou zero novos artefactos parciais. [Registo dos ensaios](sessoes/2026-11-23-recuperacao-e-polling.md)
- **Como foi testado:** Execução de 76 testes em pytest com `.venv/bin/python -m pytest -q Tools/video/tests` e inspeção manual do volume Docker `image_data`.

---

#### Incremento U-01 — Snapshot Persistente do Estado da Execução no MongoDB
`[FEITO E VERIFICADO]`

1. **O que era o problema:** O estado do processamento de um projeto existia unicamente em mensagens voláteis do RabbitMQ e na memória dos navegadores abertos. Se o utilizador recarregasse a página, o backend não tinha nenhum registo persistido que dissesse se o projeto estava a correr ou em que percentagem ia.
2. **O que acontecia antes:** O documento do projeto no MongoDB guardava apenas a lista de imagens e a versão do projeto. Não existia nenhum campo a indicar o estado da execução corrente.
3. **O que acontece agora:** O subdocumento opcional `processingRun` representa a última execução. Guarda o token, o estado, o desfecho, as datas e um array `videos` com o progresso de cada item. A próxima execução substitui esse snapshot.
4. **Porque foi feito assim:** O cliente autorizado pode obter o estado atual pela API ao abrir o projeto, mesmo que tenha perdido eventos do WebSocket.
5. **Onde está no código:** O esquema está em `projects/models/project.js` e `startProcessingRun` em `projects/utils/processingRun.js`.
- **Exemplo ilustrativo:** Uma execução com `runToken: 1` e `state: "running"` pode ter um elemento em `videos` com `mediaId: "video-a"` e `progress: 45`.
- **Como foi testado:** A suíte `projects/tests/processing-run.test.js` cobre as transições e a validação do modelo. As regressões em MongoDB exercitam as edições concorrentes. [Registo de F2/F3](sessoes/2026-11-23-f2-f3.md)

---

#### Incremento U-02 — Validação e Gravação Monotónica de Eventos de Progresso
`[FEITO E VERIFICADO]`

1. **O que era o problema:** Mensagens de rede podem chegar fora de ordem. Se o trabalhador emitir um progresso de 40% e logo a seguir emitir 50%, uma lentidão na rede podia fazer com que a mensagem de 40% fosse processada depois da de 50%, fazendo a barra de progresso do utilizador regredir (andar para trás).
2. **O que acontecia antes:** O orquestrador não validava a monotonia das percentagens nem filtrava mensagens atrasadas pertencentes a execuções anteriores que já tinham sido canceladas.
3. **O que acontece agora:** O orquestrador aceita uma mensagem de progresso se os identificadores coincidirem, o token pertencer à execução ativa, o estado for `running` e a percentagem avançar para o vídeo correspondente. Também compara o timestamp com o último desse vídeo. Eventos atrasados, duplicados ou antigos são ignorados.
4. **Porque foi feito assim:** A garantia de monotonia impede que a interface do utilizador trema ou mostre valores inconsistentes devido a oscilações normais de latência em sistemas distribuídos.
5. **Onde está no código:** A validação está em `projects/utils/videoProgress.js` e a gravação em `projects/controllers/project.js:updateVideoProgressIfActive`.
- **Exemplo concreto:** Se o vídeo `mandela.mp4` estiver com 65% registado no MongoDB e chegar uma mensagem atrasada com 60%, o orquestrador ignora o valor 60% e mantém os 65%. Quando chega a mensagem de 70%, o registo é atualizado atómicamente no MongoDB e reencaminhado via WebSocket para o navegador.
- **Como foi testado:** A suíte `projects/tests/video-progress.test.js` verifica eventos inválidos, duplicados e antigos. A regressão de F3 em MongoDB verifica a ordem independente por vídeo.

---

#### Incremento U-03 — Rota HTTP Segura de Consulta do Estado de Execução
`[FEITO E VERIFICADO]`

1. **O que era o problema:** O frontend precisava de uma forma fiável de obter o estado atual do processamento logo ao abrir a página, sem depender exclusivamente da chegada de mensagens WebSocket.
2. **O que acontecia antes:** Não existia nenhum ponto de acesso (*endpoint*) na API para consultar o progresso de um projeto. A interface dependia unicamente de estar ligada à sala de WebSockets no exato momento em que os eventos eram transmitidos.
3. **O que acontece agora:** A rota autenticada `GET /api-gateway/projects/:user/:project/processing-status` devolve uma projeção de `processingRun`. O dono tem acesso direto. Um convidado autenticado pode indicar `owner` e um link válido em `share` na query. Uma sessão ausente recebe HTTP 401 e um terceiro sem permissão recebe HTTP 403.
4. **Porque foi feito assim:** Segue o princípio arquitetural REST e permite o padrão de *polling* de segurança: o cliente faz uma pergunta direta à API assim que ganha foco ou reconecta a ligação à rede.
5. **Onde está no código:** A rota está em `projects/routes/projects.js`, a projeção em `projects/utils/processingStatus.js` e a consulta do frontend em `frontend/lib/queries/projects.ts`.
- **Como foi testado:** A suíte `projects/tests/processing-status.test.js` verifica a projeção e a autorização. Os ensaios reais confirmaram HTTP 200 para dono, leitor e editor, HTTP 403 para terceiro e 401 sem sessão. [Regressão pela API](sessoes/2026-11-24-reentrega-resultados.md)

---

#### Incremento U-04 — Painel Não Bloqueante e Reconciliação no Cliente (Frontend)
`[FEITO E VERIFICADO]`

1. **O que era o problema:** A janela modal cobria a totalidade do ecrã e impedia a navegação. Ao sair da página ou recarregar com a tecla F5, o utilizador perdia o controlo visual do processamento.
2. **O que acontecia antes:** A página exibia uma barreira cinzenta intransponível. Mudar de página significava perder o indicador de progresso para sempre.
3. **O que acontece agora:** O painel do dashboard permite acompanhar um projeto enquanto o utilizador navega para outros. Mostra o progresso, liga ao projeto acompanhado e permite cancelar a quem tem permissão de edição. A referência ao projeto fica no `sessionStorage` do separador. Ao recarregar, a interface volta a consultar o estado persistido.
4. **Porque foi feito assim:** Separa o ciclo de vida da interface visual do ciclo de vida das tarefas no servidor. O utilizador recupera total liberdade de movimentos sem perder a visibilidade dos seus trabalhos longos.
5. **Onde está no código:** Em `frontend/app/dashboard/[pid]/page.tsx`, `frontend/components/dashboard-processing-status.tsx`, e no ficheiro de lógica pura de reconciliação `frontend/lib/processing-status.ts`.
- **Exemplo concreto:** O utilizador coloca um vídeo longo a processar no projeto A. De seguida, clica no menu, abre o projeto B e altera o brilho de uma foto. Na parte inferior do ecrã, o painel mantém a indicação "Processing project A... 68%". O utilizador clica em "Open project" e a interface transita suavemente de volta para o projeto A.
- **Como foi testado:** Testes de reconciliação em `frontend/tests/processing-status.test.mjs` e ensaios em Chromium com Playwright na revisão final. [Registo de QS-02](sessoes/2026-11-24-validacao-final-3cb1b74.md#qs-02--operabilidade)

---

### 4.5 Defeitos Encontrados nas Validações (F1 a F9) e o Seu Estado

Durante a auditoria profunda realizada a 21 de novembro de 2026 (`docs/fase-2-auditoria.md`), foram formalmente catalogados 9 defeitos e vulnerabilidades (designados de F1 a F9). Abaixo apresenta-se o estado e resolução de cada um:

| Código | Dimensão e Severidade | Descrição do Problema | Estado e Resolução |
|---|---|---|---|
| **F1** | Orquestração — **Crítica** | Eliminação indevida de resultados em finalizações simultâneas de lotes de vídeo concorrentes. | **[FEITO E VERIFICADO]** Corrigido no commit `7757555`. A função `discardRunResults` valida a persistência antes de apagar qualquer ficheiro. |
| **F2** | Estado Persistente — **Alta** | Uma edição podia repor o estado `running` após a conclusão ou restaurar um token que já tinha sido invalidado pela falha. | A edição grava apenas os campos modificados em `projects/controllers/project.js`. A remoção de um efeito e o eventual regresso aos resultados anteriores usam a mesma gravação com controlo de versão. |
| **F3** | Progresso entre Réplicas — **Alta** | A data global do lote impedia que um vídeo aceitasse um evento válido após outro vídeo ter recebido um evento mais recente. | `projects/controllers/project.js` valida a data e a percentagem por vídeo. O operador `$max` conserva a data mais recente do lote. |
| **F4** | Identidade e Autorização — **Alta** | O serviço interno `projects` confia em cabeçalhos vindos do gateway. | O acesso a `processing-status` foi verificado pelo gateway para dono, leitor, editor, terceiro e sessão ausente. O isolamento das portas internas continua como dívida de implantação. |
| **F5** | Cliente e Permissões — **Alta** | Recarregamento com a tecla F5 abria resultados antigos prematuramente; botões de cancelamento ficavam visíveis a utilizadores que eram apenas leitores. | **[FEITO E VERIFICADO]** Corrigido na sessão de fecho da Fase 2 (`docs/sessoes/2026-11-22-fecho-fase-2.md`). Distingue snapshot inicial de transição observada e oculta botões a quem não tem permissão de escrita. |
| **F6** | Instrumento de Avaliação — **Alta** | O avaliador esperava pelo fim de A antes de observar B, inflacionando a duração de B quando este acabava primeiro. | A função `wait_for_results` consulta A e B na mesma ronda e verifica a contagem e unicidade dos resultados. |
| **F7** | Mensageria e Resiliência — **Alta** | As ferramentas de imagem usam confirmação automática imediata (`auto_ack=True`). O consumidor de `projects` perdia a subscrição após reiniciar RabbitMQ. | QS-03 verificou a reconexão automática de `projects` e a reentrega do trabalho de vídeo. A confirmação automática das ferramentas de imagem continua como dívida. |
| **F8** | Quotas e Perfis — **Média** | O cancelamento devolvia operações avançadas de imagem e retinha as operações de vídeo. | Corrigida e verificada em separado com contas gratuitas. As campanhas dos requisitos escolhidos usaram contas premium. |
| **F9** | Ambiente e Empacotamento — **Média** | O `frontend/Dockerfile` instala dependências antes de copiar o ficheiro de bloqueio `bun.lockb`. | O build de produção passou com 13 páginas geradas e três avisos de lint já existentes. O Dockerfile herdado conserva a resolução de dependências fora do lockfile e o build precisa de acesso a Google Fonts. |

No ensaio de F3, o vídeo A avançou com um evento das `10:00:10` e o vídeo B avançou com um evento das `10:00:09` que chegou depois. A data global permaneceu nas `10:00:10`. Eventos repetidos ou antigos para o mesmo vídeo continuaram a ser rejeitados. [Regressões de F2 e F3](sessoes/2026-11-23-f2-f3.md)

#### Reentrega de resultados já gravados

Se `projects` for interrompido depois de gravar uma saída e antes de remover o respetivo trabalho, o RabbitMQ pode entregar de novo a mesma resposta. A revisão `3cb1b74` usa uma chave única em MongoDB por trabalho e posição da saída. O serviço reutiliza o resultado existente, grava apenas os fotogramas em falta e remove o upload redundante quando duas cópias concorrem pela mesma chave. Os documentos antigos sem essa chave continuam legíveis.

O teste específico injetou a interrupção com MongoDB real e uploads simulados. A repetição preservou o ID do resultado, efetuou um só upload e concluiu o lote. A regressão separada pela API verificou downloads e ZIP com armazenamento real. [Prova de reentrega](sessoes/2026-11-24-reentrega-resultados.md)

---

### 4.6 Resultados das Medições Numéricas: Linha de Base vs. Solução Final

Todas as medições foram executadas no mesmo computador físico (processador Intel Core i7-13650HX de 20 núcleos, 32 GB de RAM, sistema operativo Linux x86_64, Docker Engine 29.9.3). Os números apresentados são reais, extraídos diretamente dos relatórios de teste gerados pela ferramenta oficial (`evaluation/summarize.py` e logs da sessão de 22/11/2026).

#### Eficiência de Desempenho · Capacidade de Vídeo

O cenário usa um vídeo de 177 s com legendagem em A e três vídeos curtos com brilho em B. O avaliador submete B 1,5 s após A. Cada série tem um aquecimento e três ensaios medidos. O aquecimento fica fora das médias.

| Métrica | Base oficial · 1 réplica | Comparação posterior · 1 réplica | Revisão final `3cb1b74` · 2 réplicas |
| --- | ---: | ---: | ---: |
| **Espera de B (`b_wait_seconds`)** | **61,727 s** | **82,242 s** | **0,123 s** |
| Duração de B | 68,374 s | 90,196 s | 10,347 s |
| Duração de A | 63,888 s | 85,048 s | 89,749 s |
| Duração total do lote | 69,925 s | 91,755 s | 89,749 s |
| Máximo de mensagens prontas | 3 | 3 | 2 |
| Máximo de mensagens por confirmar | 1 | 1 | 2 |
| Pico de CPU agregado | 830,810% | 756,550% | 754,277% |
| Pico de RAM agregado | 3 050 500 522 B | 2 860 448 219 B | 4 252 017 622 B |

A espera de B ficou entre 0,112955 e 0,137493 s na revisão final, dentro do alvo de 15 s e do mínimo aceitável de 30 s. B terminou primeiro nos três ensaios. O avaliador confirmou um resultado de A e três resultados distintos de B. As duas réplicas tiveram um pico de RAM médio de cerca de 4,25 GB, face a 2,86 GB na comparação posterior com uma réplica. As diferenças de ambiente e de instrumentação entre campanhas limitam a atribuição das variações de A e do tempo total exclusivamente ao número de réplicas. A primeira campanha de 22/11 tinha obtido 0,113 s de espera média de B e a repetição em `fb18924` obteve 0,142 s. [Campanha de 22/11](sessoes/2026-11-22-fecho-fase-2.md) · [Validação integrada](sessoes/2026-11-24-validacao-entrega.md) · [Resultados finais por ensaio](sessoes/2026-11-24-validacao-final-3cb1b74.md)

---

#### Tabela Resumo: Usabilidade (Operabilidade da Interface)
A medição avalia o comportamento da interface no navegador Google Chrome 157.0.8103.50 com resolução de 1280 × 720 píxeis, durante o processamento de legendas num vídeo de 10 segundos.

| Métrica Avaliada | Linha de Base Oficial | Solução Final (Chromium) | Meta Estabelecida | Veredito |
|---|---:|---:|---:|:---:|
| **Ações concluídas durante processamento ativo** | **6 / 12 (50%)** | **12 / 12 (100%)** | **12 / 12 (100%)** | **Meta atingida a 100%** |
| Ação: Abrir o projeto B | 3 / 3 (100%) | 3 / 3 (100%) | 3 / 3 (100%) | Aprovado |
| Ação: Interagir com a barra de ferramentas em B | 3 / 3 (100%) | 3 / 3 (100%) | 3 / 3 (100%) | Aprovado |
| Ação: Regressar ao projeto A | 0 / 3 (0%) | 3 / 3 (100%) | 3 / 3 (100%) | Recuperado integralmente |
| Ação: Confirmar que o estado de A continua a avançar | 0 / 3 (0%) | 3 / 3 (100%) | 3 / 3 (100%) | Recuperado integralmente |
| **Recuperação após navegação entre páginas** | **0 / 3 (0%)** | **3 / 3 (100%)** | **3 / 3 (100%)** | **Meta atingida a 100%** |
| **Recuperação após recarregar a página (F5)** | **0 / 3 (0%)** | **3 / 3 (100%)** | **3 / 3 (100%)** | **Meta atingida a 100%** |
| **Recuperação após corte temporário de rede** | Não medido | **3 / 3 (100%)** | 3 / 3 (100%) | Aprovado |
| Conclusões falsas ou prematuras | Não registado | **0 em todos os ensaios** | 0 | Critério de qualidade cumprido |
| Duração média da legendagem | 6,029 s | 7,243 s | Informativa | Duração observada na revisão final |
| Pedidos HTTP à API por ensaio | 28 | 40, 41 e 41 (9 de estado em cada ensaio) | Informativa | Tráfego observado, incluindo navegação e reconexão |

Num ensaio complementar, um observador de status a 1 Hz acrescentou quatro pedidos e 1 048 bytes de corpo de resposta em quatro segundos, com mediana de 7,75 ms por pedido. [Medição de polling](sessoes/2026-11-23-recuperacao-e-polling.md)

Na revisão final, as quatro ações de cada ensaio foram realizadas com A ainda em execução. Os três percursos de recuperação passaram em todos os ensaios e todos os vídeos ficaram descarregáveis. Os ficheiros coincidiram por SHA-256 com o vídeo legendado de referência. Os pedidos e os tempos registados descrevem o cenário completo de interação. A medição isolada do custo HTTP de polling é a do ensaio complementar. [Validação em Chromium](sessoes/2026-11-24-validacao-final-3cb1b74.md#qs-02--operabilidade)

---

### 4.7 O Que Foi Feito nos Exercícios 6 (Blocos 1 e 2) e 7

A equipa elaborou os trabalhos práticos intercalares que servem de alicerce ao relatório final:

1. **Exercício 6 (Bloco 1) — Identificação e Comparação de Padrões Arquiteturais (`docs/exercicios/RAS-exercicio_6_bloco1_SWdesign_template_PT.md`)**:
   - *O que foi feito:* Mapeou-se a arquitetura de base e as alterações relevantes, catalogando as evidências factuais do código (`EV-01` a `EV-10`) e quatro hipóteses técnicas (`H-01` a `H-04`) na numeração original do exercício. Identificaram-se os padrões existentes: Microsserviços e Arquitetura Orientada a Eventos no padrão global; e Filtros e Condutas (*Pipes and Filters*) combinados com Trabalhador Monolítico no processamento de vídeo. Formularam-se 4 alternativas arquiteturais de evolução (`ALT-1` a `ALT-4`).
   - *Versão do exercício:* Na numeração original do Exercício 6, os resultados registados confirmam H-01 e H-02 nos cenários da campanha de 22/11.
2. **Exercício 6 (Bloco 2) — Cenários de Qualidade e Candidatos a RNF (`docs/exercicios/RAS-exercicio_6_bloco2_SWdesign_template_PT.md`)**:
   - *O que foi feito:* Caracterizaram-se formalmente os cenários de qualidade segundo a norma ISO/IEC 25010:2011: `QS-01` (para o candidato de Capacidade `CAND-1`) e `QS-02` (para o candidato de Usabilidade/Operabilidade `CAND-2`). Criou-se a matriz de compromissos (*trade-offs*) analisando o impacto cruzado das táticas sobre atributos como Fiabilidade, Portabilidade, Modularidade e Custo de Recursos.
   - *Versão do exercício:* A tabela de síntese contém os valores medidos de 22/11. Os resultados da revisão final constam da secção 4.6 deste documento.
3. **Exercício 7 — Táticas Arquiteturais e Decisões de Design (`docs/exercicios/RAS-exercicio_7_taticas_SWdesign_template_PT.md`)**:
   - *O que foi feito:* Selecionaram-se e justificaram-se as táticas arquiteturais: `TAT-01` (escalação horizontal de réplicas com fila partilhada) para satisfazer `DA-1` (Decisão Arquitetural 1); e `TAT-04` (persistência assíncrona do estado com reconciliação no cliente) para satisfazer `DA-2` (Decisão Arquitetural 2). As táticas que introduziam novas funcionalidades aos utilizadores foram explicitamente rejeitadas para respeitar a diretriz docente de refactoring puro.
   - *Versão do exercício:* O documento referencia as regressões P-02 e U-04 e as medições de 22/11 para as duas decisões.

Os documentos dos exercícios mantêm os seus identificadores originais. O relatório Typst reindexa as mesmas evidências e hipóteses pela ordem da primeira utilização; os números não devem ser comparados sem esta correspondência:

| Tipo | ID original do exercício | ID no relatório final | Assunto |
| --- | --- | --- | --- |
| EV | EV-01 | EV-04 | Worker de vídeo: prefetch e confirmação manual |
| EV | EV-02 | EV-08 | Uma réplica de vídeo por omissão no Compose |
| EV | EV-03 | EV-05 | Faster-Whisper síncrono em CPU/int8 |
| EV | EV-04 | EV-03 | Validação de upload e despacho por tipo de media |
| EV | EV-05 | EV-10 | Estado volátil e modal bloqueante na interface |
| EV | EV-06 | EV-06 | Snapshot persistente do processamento |
| EV | EV-07 | EV-09 | `auto_ack=True` nas ferramentas de imagem |
| EV | EV-08 | EV-02 | Ligação RabbitMQ aberta por publicação |
| EV | EV-09 | EV-01 | Validação TLS interna desativada |
| EV | EV-10 | EV-07 | Rota autenticada de estado do processamento |
| H | H-01 | H-03 | Capacidade: espera de B com uma e duas réplicas |
| H | H-02 | H-04 | Usabilidade: ações e recuperação do estado |
| H | H-03 | H-01 | Condições de corrida no fecho do lote |
| H | H-04 | H-02 | Possível gargalo ou falha do volume partilhado |

---

### 4.8 Estado do Relatório Final em Typst (`docs/src-doc-fase2-template/`)

O rascunho Typst tem conteúdo de arquitetura, padrões, qualidade, táticas, medições, conclusões, uso de IA e anexos. Foi compilado localmente para revisão. O historial Git regista revisões posteriores da introdução e da vista arquitetural. Para a versão final do relatório, a equipa deve identificar os resultados pelo SHA da respetiva campanha, referenciar a prova de reentrega e registar a revisão humana e a reprodução independente. [Rascunho e instruções](src-doc-fase2-template/README.md) · [Registo de D-01 e D-02](sessoes/2026-11-23-d01-d02.md)

---

## 5. Estado de Fecho e Reprodução

| Entregável | Estado | Como verificar |
| --- | --- | --- |
| Código da aplicação | `3cb1b74` publicado e validado. | Os ensaios completos de QS-01 e QS-02 passaram e a regressão específica da reentrega está registada. [Sessão final](sessoes/2026-11-24-validacao-final-3cb1b74.md) |
| Evidência experimental | Pacote final verificado a partir de uma extração limpa. Inclui o D-01 original. | Obter `picturas-phase2-final-3cb1b74.tar.gz` e o respetivo `.sha256`, verificar o arquivo, extrair e correr `python3 verify_final.py`. Os ficheiros de evidência são partilhados à parte do Git. [Guia de reprodução](../evaluation/phase2-reproduction.md) |
| Reprodução independente | A execução e o registo por outro membro da equipa estão pendentes. | Usar a revisão identificada no manifesto, um checkout limpo, as amostras verificadas e o mesmo protocolo. Registar o ambiente, os IDs e os resultados. |
| Relatório e registo de IA | Rascunho disponível para revisão da equipa. | Conferir o conteúdo e as atribuições de IA, registar a revisão humana e compilar e verificar o PDF final. [Fonte Typst](src-doc-fase2-template/README.md) |

---

## 6. Riscos e Pontos Fracos Conhecidos (Com Franqueza)

Uma postura de engenharia de software rigorosa exige identificar sem reservas as fragilidades e limitações da solução atual:

1. **Variação entre campanhas.** A duração média de A foi 63,888 s na linha de base oficial, 85,048 s na repetição com uma réplica e 89,749 s na revisão final. As revisões, as imagens e os instrumentos diferiram. A atribuição das diferenças ao número de réplicas é limitada por essas condições. [Comparação final](sessoes/2026-11-24-validacao-final-3cb1b74.md#qs-01--capacidade)
2. **Consumo de memória.** O pico agregado médio de RAM foi de aproximadamente 2,86 GB na comparação com uma réplica e 4,25 GB na revisão final com duas.
3. **Configuração de implantação herdada.** O Compose publica portas internas e contém credenciais de desenvolvimento. Existem certificados de desenvolvimento versionados e ligações internas com verificação de TLS desativada. A stack de validação publica o nginx em `127.0.0.1:8080`. [Notas da auditoria](sessoes/2026-11-24-validacao-entrega.md#observações-de-manutenção)
4. **Âmbito da recuperação.** O QS-03 verificou uma interrupção por ensaio durante legendagem ativa. A correção de reentrega cobre saídas já registadas. Uma falha entre o upload e o registo em MongoDB pode deixar um objeto órfão, e a janela entre remover o trabalho e confirmar o lote continua por validar. [Limites da reentrega](sessoes/2026-11-24-reentrega-resultados.md)
5. **Quotas históricas.** A versão anterior a F8 guardava apenas o débito de operações avançadas para reembolso. As novas reservas registam o total debitado e a conta que pagou.

---

## 7. Glossário de Siglas, Códigos e Conceitos

Para garantir que o leitor compreende todos os identificadores que surgem no código e nos relatórios, apresenta-se o glossário completo:

- **AAC (Advanced Audio Coding)**: Formato de compressão de áudio digital padronizado de alta qualidade, utilizado por omissão nas faixas sonoras dos vídeos finais da aplicação.
- **ALT-1 a ALT-4 (Alternativas Arquiteturais)**: Identificadores das opções arquiteturais concebidas no Exercício 6 Bloco 1:
  - `ALT-1`: Escalar réplicas do trabalhador de vídeo mantendo o pipeline monolítico (opção adotada na decisão DA-1);
  - `ALT-2`: Separar o microsserviço de vídeo em microsserviços individuais por cada efeito (rejeitada por complexidade e overhead);
  - `ALT-3`: Criar filas RabbitMQ dedicadas para tarefas pesadas como legendas (rejeitada por exigir lógica de roteamento complexa);
  - `ALT-4`: Migrar a descodificação e aplicação de filtros para a placa gráfica GPU (rejeitada por falta de garantia de hardware em todos os ambientes de teste).
- **B-01 a B-04 (Tarefas de Baseline Oficial)**: Conjunto de tarefas de medição da linha de base realizadas a 17 de novembro de 2026:
  - `B-01`: Adaptação do script de avaliação para observar múltiplos contentores em simultâneo;
  - `B-02`: Medição formal da baseline de capacidade (desempenho de vídeo com 1 réplica);
  - `B-03`: Medição formal da baseline de usabilidade no navegador Chromium;
  - `B-04`: Reunião de equipa de aprovação e congelamento dos dados da baseline.
- **`b_wait_seconds`**: Métrica de tempo (em segundos) que mede a capacidade de resposta: intervalo entre o clique de submissão do projeto B e o início do processamento do seu primeiro vídeo.
- **CAND-1 e CAND-2 (Candidatos a RNF)**: Requisitos não funcionais candidatos formalizados no Exercício 6 Bloco 2:
  - `CAND-1`: Eficiência de Desempenho / Capacidade (escalabilidade no processamento de vídeo);
  - `CAND-2`: Usabilidade / Operabilidade (interface recuperável e não bloqueante durante o trabalho).
- **CPU (Central Processing Unit)**: Processador principal do computador onde correm as instruções lógicas do sistema operativo e das aplicações.
- **DA-1 e DA-2 (Decisões Arquiteturais)**: Decisões de refactoring consolidadas no Exercício 7:
  - `DA-1`: Implementar 2 réplicas de `video_tool` consumindo de `video_queue` com prefetch 1;
  - `DA-2`: Persistir o estado da execução no MongoDB e desacoplar o dashboard através de um painel global partilhado.
- **EV-01 a EV-10 (Evidências de Arquitetura)**: Evidências do código da arquitetura de base e das alterações da Fase 2, registadas com a numeração original no Exercício 6 Bloco 1. Nessa numeração, `EV-01` identifica o worker de vídeo e `EV-05` a interface com estado volátil e modal bloqueante; o relatório final usa a correspondência acima.
- **F1 a F9 (Falhas e Defeitos da Auditoria)**: Catálogo dos 9 pontos críticos identificados na auditoria de 21 de novembro (detalhados na secção 4.5).
- **ffmpeg / ffprobe**: Conjunto de ferramentas e bibliotecas de linha de comando em código aberto líderes de mercado para manipulação, conversão, descodificação e análise de formatos multimédia de áudio e vídeo.
- **H-01 a H-04 (Hipóteses de Arquitetura)**: Quatro suposições técnicas formuladas no Exercício 6 Bloco 1, na numeração original, que necessitavam de validação empírica nos testes de laboratório.
- **H.264 (AVC)**: Norma de codificação e compressão de vídeo amplamente compatível com todos os navegadores web modernos, utilizada como formato de exportação no PictuRAS.
- **ISO/IEC 25010:2011**: Norma internacional da ISO que estabelece um modelo de referência de qualidade de produto de software, decomposto em 8 características principais (como Eficiência de Desempenho, Usabilidade e Fiabilidade).
- **JWT (JSON Web Token)**: Padrão aberto de segurança para partilha de declarações de identidade autenticadas entre cliente e servidor, assinado digitalmente por chave secreta.
- **Makespan**: Duração total de ponta a ponta (em segundos) necessária para concluir a totalidade de um lote de trabalhos concorrentes, desde o arranque do primeiro até à finalização do último.
- **M-01 a M-04 (Tarefas de Medição Final)**: Fases de quantificação da melhoria obtida após o refactoring:
  - `M-01`: Congelamento do ambiente experimental e verificação das réplicas ativas;
  - `M-02`: Campanha de ensaios de capacidade com duas réplicas;
  - `M-03`: Campanha de ensaios de usabilidade em navegador Chromium;
  - `M-04`: Confronto estatístico entre a baseline e o resultado final.
- **Monotónico**: Propriedade matemática de uma sequência numérica que nunca decresce (só pode aumentar ou manter o valor), utilizada para garantir que o progresso de 0 a 100% nunca regride.
- **MVP (Minimum Viable Product)**: Versão simplificada de um produto com os requisitos mínimos indispensáveis para demonstrar a sua funcionalidade aos utilizadores.
- **P-01 a P-03 (Tarefas de Desempenho / Performance)**: Incrementos de engenharia para o requisito de capacidade:
  - `P-01`: Escalação para 2 réplicas do trabalhador de vídeo;
  - `P-02`: Preservação de integridade de ficheiros e barreiras de processo em finalizações concorrentes;
  - `P-03`: Medição de recursos, limpeza de temporários `.part` e verificação de recuperação.
- **Prefetch Count**: Definição de configuração no protocolo RabbitMQ que limita quantas mensagens não confirmadas um trabalhador pode puxar da fila de cada vez (`prefetch_count=1` garante que um trabalhador só retira um novo trabalho quando terminar e confirmar o anterior).
- **QS-01 e QS-02 (Quality Scenarios)**: Cenários de qualidade formais especificados no Exercício 6 Bloco 2:
  - `QS-01`: Cenário de sobrecarga com submissão imediata de projetos A e B;
  - `QS-02`: Cenário de usabilidade com navegação concorrente e recarregamento durante execução ativa.
- **R-01 a R-04 (Tarefas de Regressão)**: Verificação sistemática para garantir que o código novo não partiu funcionalidades antigas:
  - `R-01`: Regressão do orquestrador de projetos em Node.js;
  - `R-02`: Regressão do trabalhador de vídeo em Python pytest;
  - `R-03`: Regressão dos componentes de interface no frontend;
  - `R-04`: Regressão dos scripts e instrumentos de avaliação.
- **RAM (Random Access Memory)**: Memória volátil de acesso rápido onde os programas e contentores guardam temporariamente dados e imagens durante o processamento.
- **RNF**: Requisito Não Funcional (atributo de qualidade que define *como* o sistema deve operar, e não *o que* deve fazer).
- **Rollback**: Ação de desfazer uma alteração ou regressar a um estado anteriormente conhecido como válido e estável.
- **TAT-01 a TAT-05 (Táticas Candidatas)**: Catálogo de táticas de arquitetura analisadas no Exercício 7 para responder aos cenários de qualidade.
- **Typst**: Sistema moderno de escrita e paginação de documentos baseado em código, concebido como uma alternativa eficiente e veloz ao LaTeX.
- **U-01 a U-04 (Tarefas de Usabilidade)**: Incrementos de engenharia para o requisito de operabilidade:
  - `U-01`: Criação do modelo de estado de execução persistente no MongoDB;
  - `U-02`: Roteamento e persistência monotónica de eventos de progresso dos trabalhadores;
  - `U-03`: Ponto de acesso HTTP seguro para leitura do estado de processamento;
  - `U-04`: Eliminação da janela bloqueante e introdução do painel global recuperável no frontend.
- **WebSocket**: Protocolo de comunicação bidirecional em tempo real sobre uma única ligação TCP contínua entre o navegador do utilizador e o servidor.

---

## 8. Lacunas e Informações Por Confirmar

- A imagem original do worker e o driver exato de browser da linha de base histórica estão indisponíveis. O D-01 conserva os dados brutos, a amostra e o protocolo para verificar e repetir os cenários. [Guia de reprodução](../evaluation/phase2-reproduction.md)
- A reprodução independente e a revisão humana do relatório e do registo de IA aguardam registo pela equipa.
- O ensaio de polling mediu o custo HTTP de um observador a 1 Hz. O custo em CPU e memória e o efeito de vários observadores ficaram por medir. [Ensaio de polling](sessoes/2026-11-23-recuperacao-e-polling.md)
