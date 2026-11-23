# Relatório Explicativo do Projeto PictuRAS (Fase 2)

---

## 1. Resumo de Uma Página

O PictuRAS é uma plataforma web em microserviços Docker para edição em lote de imagens e vídeos, organizada em projetos onde os utilizadores aplicam uma sequência ordenada de efeitos (pipeline).
Na presente Fase 2 da unidade curricular de Requisitos e Arquiteturas de Software (RAS), a equipa tem como missão melhorar dois Requisitos Não Funcionais (RNF) através de refactoring arquitetural, sem adicionar novas funcionalidades aos utilizadores.
Os dois requisitos escolhidos foram a Eficiência de Desempenho (Capacidade de processamento de vídeo) e a Usabilidade (Operabilidade da interface durante o processamento).
O trabalho técnico principal está concluído e validado: a capacidade foi aumentada através da duplicação dos trabalhadores de vídeo com fila única, e a operabilidade foi resolvida com persistência de estado e painel não bloqueante no cliente.
No ensaio de desempenho final, a espera do segundo projeto desceu de 61,727 segundos para 0,113 segundos, superando a meta de 15 segundos.
No ensaio de usabilidade em Chromium, a interface atingiu 12 em 12 ações concluídas (100%), eliminando as falhas observadas na linha de base inicial.
O defeito crítico de concorrência F1 (perda de ficheiros em finalizações simultâneas) e as falhas de interface F5 (recarregamento com a tecla F5 e permissões de partilha) foram integralmente corrigidos e verificados.
O rascunho Typst incorpora os exercícios, as medições e o registo de IA. Falta a revisão da equipa e a reprodução independente. [Estado da entrega](sessoes/2026-11-23-d01-d02.md)
Falta igualmente confirmar a situação administrativa da entrega da Fase 2, cuja data oficial no enunciado inicial era 20 de novembro de 2026.
O sistema encontra-se tecnicamente funcional, com testes verdes e medições finais recolhidas e consolidadas.

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
De acordo com o documento de diretrizes docentes (`docs/fase-2-guidelines.md` e enunciado da Fase 2):
1. **Relatório Técnico da Fase 2**: documento em formato Typst (compilado em PDF) estruturado em cinco partes:
   - Parte I: Introdução e Âmbito da Arquitetura (enquadramento e vista factual herdada da Fase 1);
   - Parte II: Diagnóstico Arquitetural (Exercício 6 Bloco 1, com identificação de padrões, forças, fraquezas e alternativas arquiteturais);
   - Parte III: Qualidade e Requisitos Não Funcionais (Exercício 6 Bloco 2, com cenários de qualidade quantificados segundo a norma ISO/IEC 25010 e matriz de compromissos);
   - Parte IV: Táticas, Decisões, Medição e Resultados (Exercício 7, com formulação de decisões arquiteturais, medições antes/depois e preservação funcional);
   - Parte V: Síntese e Utilização de Inteligência Artificial (conclusões e documentação detalhada das ferramentas de IA usadas, tarefas apoiadas, erros da IA e validações humanas realizadas).
2. **Repositório de Código Fonte**: código com o refactoring implementado, acompanhado por testes automatizados (testes unitários e testes de integração que asseguram que a aplicação continua a funcionar sem regressões funcionais).
3. **Evidências Experimentais e Scripts de Avaliação**: conjunto de scripts de teste, registos de execução (*logs*), manifestos com identificadores de versão de imagens Docker e dados brutos que permitam a qualquer avaliador reproduzir exatamente as medições da linha de base e da solução final.

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
- **Situação Administrativa Atual**: A data de 20 de novembro já foi ultrapassada no calendário civil. Na documentação local e no histórico do repositório não encontrei evidência de recibo de submissão nem de anúncio docente sobre prorrogação de prazos (auditoria registada em `docs/fase-2-auditoria.md#L11-L12`). A equipa deve esclarecer de imediato junto dos docentes se existiu uma extensão de prazo ou se a entrega foi realizada por outra via (e.g., plataforma Blackboard/e-Learning da Universidade do Minho).

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
```

1. **Gate Oficial da Linha de Base (Tarefas B-01 a B-04) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* O enunciado docente proíbe tocar no código da aplicação antes de registar o desempenho do sistema original.
   - *O que se fez:* Adaptou-se a ferramenta de avaliação (`evaluation/run_scenario.py` e `evaluation/summarize.py`) para recolher métricas agregadas de múltiplos contentores Docker (B-01). No dia 17 de novembro de 2026, sobre o commit original `0523102` (tag `phase2-base`), mediram-se a linha de base de capacidade (B-02) e a linha de base de usabilidade (B-03), sendo os resultados aprovados formalmente na reunião de equipa B-04 (`specs/002-nfr-improvement/tasks.md#L14-L65`).
2. **Tática de Capacidade (Tarefas P-01 a P-03) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* A capacidade do processamento de vídeo era o estrangulamento mais pesado do backend, afetando diretamente a arquitetura de microserviços.
   - *O que se fez:* Em P-01 iniciaram-se 2 réplicas do contentor `video_tool` a consumir da mesma fila RabbitMQ com limite de 1 trabalho por réplica (`prefetch_count=1`). Em P-02 reestruturou-se a orquestração em `projects` para registar barreiras de processos antes do despacho. Em P-03 verificou-se a libertação de ficheiros temporários `.part` e a persistência de modelos em cache de disco (`docs/fase-2-implementacao.md#L64-L166`).
3. **Tática de Operabilidade (Tarefas U-01 a U-04) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* Para permitir que o utilizador continue a interagir com a interface enquanto um vídeo processa, o backend tem de guardar o estado no MongoDB para que o frontend o consiga consultar após qualquer navegação.
   - *O que se fez:* Em U-01 criou-se o modelo persistente `processingRun` no MongoDB. Em U-02 ligou-se o envio de percentagens do trabalhador de vídeo para o orquestrador via RabbitMQ. Em U-03 disponibilizou-se a rota HTTP segura de consulta `GET /projects/:owner/:project/processing-status`. Em U-04 removeu-se a janela modal bloqueante do ecrã e introduziu-se uma barra inferior de estado global (`docs/fase-2-implementacao.md#L175-L280`).
4. **Auditoria de Qualidade e Descoberta de Falhas (21 de novembro de 2026) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* Antes de declarar a Fase 2 como concluída, realizou-se uma auditoria minuciosa ao código e aos testes integrados para garantir que não existiam efeitos secundários escondidos.
   - *O que se fez:* Descobriram-se 9 pontos críticos (de F1 a F9, descritos em `docs/fase-2-auditoria.md`). O mais gravoso era o defeito F1: quando dois vídeos do mesmo projeto terminavam no mesmo milissegundo em trabalhadores diferentes, a rotina de limpeza apagava todos os ficheiros resultantes do armazenamento S3, deixando o projeto concluído mas vazio.
5. **Correção de F1, Resolução de F5 e Regressão Integrada (22 de novembro de 2026) — [FEITO E VERIFICADO]**:
   - *Porquê nesta ordem:* Era imperativo corrigir a perda de resultados e os problemas de interface antes de realizar as medições definitivas.
   - *O que se fez:* No commit `7757555` corrigiu-se F1 em `projects/routes/projects.js:discardRunResults`. Em F5 blindou-se a interface contra recarregamentos acidentais de página (F5) e perda de permissões de partilha. Em seguida, executou-se a bateria de testes integrados e a campanha de medição final (`docs/sessoes/2026-11-22-fecho-fase-2.md`).

---

## 4. Explicação Detalhada do Projeto PictuRAS (Fase 2)

### 4.1 O Que Faz a Aplicação (A Perspetiva do Utilizador)
O PictuRAS é uma aplicação web para edição multimédia que funciona através de um navegador web. O utilizador autentica-se com a sua conta pessoal (perfil anónimo, gratuito ou premium), cria um **projeto** e carrega para esse projeto um conjunto de ficheiros de imagem (PNG, JPEG) ou de vídeo (MP4, MOV, WebM).
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
                                      (binarization, cut, ...)                        (video_tool: 2 réplicas)
```

- **Porta de Entrada (Nginx)**: Todo o tráfego externo entra pela porta segura HTTPS 8080. O servidor Nginx encaminha o tráfego da rota `/` para o `frontend` (construído em Next.js 15, React 19 e TypeScript), as rotas `/api-gateway/` para o `apiGateway` (servidor Express em Node.js), a rota `/socket.io` para o `wsGateway` (servidor de eventos em tempo real) e a rota `/s3/` para o sistema de ficheiros em nuvem `imageStorageService` (SeaweedFS, um armazenamento compatível com o protocolo S3 da Amazon).
- **Serviço de Utilizadores (`users`)**: Gere contas, autenticações com assinatura digital JWT (JSON Web Token, um código encriptado que comprova a identidade do utilizador) e controla o saldo de operações diárias em MongoDB.
- **Serviço de Projetos (`projects`)**: Atua como o cérebro orquestrador. Guarda no MongoDB a lista de projetos, os ficheiros associados, as ferramentas configuradas e o estado de execução.
- **Fila de Mensagens (RabbitMQ)**: Um intermediário de mensageria assíncrona (*message broker*) que gere filas de tarefas. Os pedidos não bloqueiam os servidores web: são colocados em filas e retirados pelos trabalhadores.
- **Trabalhadores de Imagem (`Tools/<tool>/`)**: Microsserviços Python que processam imagens fotograma a fotograma (brilho, corte, rotação, filtros com inteligência artificial).
- **Trabalhadores de Vídeo (`Tools/video/`, serviço `video_tool`)**: Microsserviço Python especializado em vídeo. Ao contrário das imagens, um vídeo não é decomposto em mensagens separadas por cada filtro: o orquestrador envia uma única mensagem com o pipeline completo para a fila `video_queue`. O trabalhador lê o ficheiro de vídeo, descodifica com a biblioteca multimédia `ffmpeg`, aplica os filtros de fotogramas de forma combinada em memória, processa áudio se necessário, transcreve fala com o modelo Faster-Whisper, codifica o ficheiro final em formato MP4 (com codec de vídeo H.264 e áudio AAC) e devolve a resposta na fila `project_queue`.

#### O Caminho de um Pedido de Vídeo Passo a Passo:
1. O utilizador clica no botão "Apply" na interface web.
2. O navegador envia um pedido HTTP `POST /api-gateway/projects/:user/:project/process` com o token JWT de autenticação no cabeçalho.
3. O `apiGateway` verifica a validade da assinatura do token JWT e reencaminha o pedido internamente para o serviço `projects`.
4. O serviço `projects` consulta o serviço `users` para debitar as operações da quota do utilizador. Em seguida, gera um identificador numérico de execução (`runToken`, por exemplo `runToken = 4`), cria os registos de barreira na coleção `Process` do MongoDB e envia uma mensagem JSON para a fila `video_queue` do RabbitMQ contendo o identificador do ficheiro e a lista de efeitos.
5. Uma das réplicas disponíveis do serviço `video_tool` retira a mensagem da fila `video_queue` (pois tem `prefetch_count=1`, aceitando apenas 1 vídeo de cada vez).
6. O trabalhador de vídeo faz o download do ficheiro original a partir do volume partilhado `image_data`, processa os fotogramas com ffmpeg, transcreve o áudio com Faster-Whisper (se o efeito `subtitles` estiver configurado) e grava o resultado num ficheiro temporário com a extensão `.part`. À medida que atinge marcos no processamento (e.g., 25%, 50%, 75%), o trabalhador envia mensagens de progresso para a fila `project_queue`.
7. O serviço `projects` consome essas mensagens de progresso da `project_queue`, valida que pertencem à execução ativa, atualiza o documento do projeto em MongoDB e reencaminha o evento para a fila `ws_queue`. O `wsGateway` recebe o evento e transmite-o por WebSocket para a interface do navegador, que atualiza a barra de progresso visual.
8. Ao terminar a codificação, o trabalhador de vídeo substitui atomicamente o ficheiro temporário `.part` pelo ficheiro definitivo `.mp4`, envia uma mensagem de conclusão para a `project_queue` e confirma a mensagem original no RabbitMQ (`ack`).
9. O serviço `projects` processa a mensagem final: guarda o resultado no MongoDB, remove o registo da coleção `Process`, comita a execução e notifica a interface web de que o vídeo final está disponível para visualização e descarregamento.

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
- **Métrica Medida:** `b_wait_seconds`, que calcula o intervalo de tempo exato (em segundos) entre o momento em que o projeto B foi submetido e o momento em que o primeiro fotograma do projeto B começou efetivamente a ser processado pelo trabalhador.
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

Aqui responde-se obrigatoriamente às 5 perguntas exigidas pelas regras de estilo para cada incremento.

---

#### Incremento P-01 — Escalação Controlada de Réplicas de Vídeo em Docker Compose
`[FEITO E VERIFICADO]`

1. **O que era o problema:** Existia apenas uma réplica do trabalhador de vídeo ligada à fila `video_queue`. Todas as mensagens eram processadas em fila indiana estrita por esse único processo.
2. **O que acontecia antes:** Quando o projeto A enviava um vídeo com legendagem demorada e o projeto B enviava vídeos curtos, o trabalhador ficava ocupado com A. O projeto B ficava retido na fila do RabbitMQ sem que ninguém lhe tocasse durante mais de um minuto.
3. **O que acontece agora:** Quando o projeto A e o projeto B chegam à fila, o trabalhador 1 consome o vídeo de A e o trabalhador 2 consome imediatamente o primeiro vídeo de B em paralelo. O projeto B arranca de forma instantânea sem esperar que A termine.
4. **Porque foi feito assim:** Optou-se por escalar réplicas independentes consumindo da mesma fila existente em vez de criar filas separadas com prioridades ou reescrever o trabalhador com multithreading complexo em Python. Cada réplica mantém `prefetch_count=1`, garantindo que nenhuma réplica acumula trabalhos em excesso na sua memória.
5. **Onde está no código:** Configurado no comando de orquestração do Compose `docker compose up -d --scale video_tool=2` e verificado na configuração do consumidor RabbitMQ em `Tools/video/video_processor.py:main` (linha onde é invocado `channel.basic_qos(prefetch_count=1)`).
- **Exemplo concreto:** No ensaio de teste, o contentor `picturas-validation-video_tool-1` assumiu o processamento do vídeo de 177 s de A às `00:00:01`, enquanto o contentor `picturas-validation-video_tool-2` começou a processar o primeiro vídeo de 10 s de B às `00:00:01.115`.
- **Como foi testado:** Smoke test documentado em `evaluation/evidence/phase2-p01-smoke-2026-11-17/`, onde o comando `rabbitmqctl list_queues name consumers` confirmou exatamente 2 consumidores na fila `video_queue`.

---

#### Incremento P-02 — Preservação de Resultados em Finalizações Concorrentes
`[FEITO E VERIFICADO]`

1. **O que era o problema:** Quando dois vídeos do mesmo projeto eram processados em paralelo por dois trabalhadores diferentes e terminavam no mesmo instante, existia uma condição de corrida (*race condition*) no orquestrador.
2. **O que acontecia antes:** Os dois trabalhadores concluíam os respetivos vídeos e enviavam a mensagem para o orquestrador em `projects/utils/processBatch.js`. Ambos removiam o seu registo `Process` do MongoDB e consultavam `countPending`. Ambos viam 0 tarefas pendentes. O primeiro a chegar fazia o commit do lote e marcava o estado como `completed`. O segundo recebia resposta de commit nulo (`committed = false`). Como `committed` era falso, o código invocava `cleanupStale(process)`. Em `projects/routes/projects.js`, a função `discardRunResults` apagava do MongoDB e do armazenamento S3 todos os ficheiros daquele token, incluindo os ficheiros acabados de guardar pelo primeiro trabalhador! O lote ficava marcado como sucesso, mas com **zero resultados**.
3. **O que acontece agora:** Quando o segundo trabalhador vê que o commit falhou e tenta limpar tarefas obsoletas, a função `discardRunResults` consulta primeiro o documento do projeto no MongoDB. Se o token pertencer à execução que está atualmente confirmada (`committedToken === token`) ou se for o token reservado para recuperação (*rollback*), a limpeza é imediatamente abortada e retorna `null`. Os ficheiros de ambos os vídeos são protegidos e preservados intactos.
4. **Porque foi feito assim:** Foi feita uma verificação de segurança no ponto central de eliminação de ficheiros (`discardRunResults`). Em vez de confiar cegamente na ordem de chegada das mensagens assíncronas do RabbitMQ, a base de dados do MongoDB funciona como árbitro de verdade.
5. **Onde está no código:** Em `projects/routes/projects.js`, função `discardRunResults` (linhas 173–182 no commit `7757555`), e na função de barreira em `projects/utils/processBatch.js:persistAndSettleProcess` (linhas 20–40).
- **Exemplo concreto:** No teste automatizado `simultaneous completion preserves both video results` (`projects/tests/process-batch.test.js`), dois vídeos terminam simultaneamente com o token `4`. Antes da correção, a contagem de resultados no final era `0`. Com a correção, a contagem final é rigorosamente `2`, com os dois identificadores de imagem `mediaIds` guardados no MongoDB e no armazenamento S3.
- **Como foi testado:** Teste unitário em `projects/tests/process-batch.test.js` e validação integrada documentada na sessão `docs/sessoes/2026-11-22-p02.md`, executada contra uma base MongoDB real com o profiler ativado, confirmando 2 ficheiros no ZIP gerado.

---

#### Incremento P-03 — Gestão de Recursos e Limpeza do Trabalhador de Vídeo
`[FEITO E VERIFICADO]`

1. **O que era o problema:** O processamento de vídeo cria ficheiros pesados em disco. Em caso de falha de energia, reinício de contentor ou erro de codificação, ficheiros temporários corrompidos podiam ficar esquecidos a encher o disco partilhado.
2. **O que acontecia antes:** Se um processo de ffmpeg sofresse uma falha a meio da codificação, o ficheiro resultante parcial podia permanecer com o nome final no disco, induzindo o utilizador em erro ao descarregar um vídeo cortado.
3. **O que acontece agora:** O trabalhador escreve sempre para ficheiros com a extensão `.part` (por exemplo, `output_video.mp4.part`). Se ocorrer uma exceção ou erro durante o processamento, um bloco de tratamento de erros apaga imediatamente o ficheiro parcial e os diretórios temporários de legendas. O ficheiro só é renomeado para a extensão final `.mp4` após a codificação ser bem-sucedida a 100%. Adicionalmente, a pasta com os modelos de inteligência artificial do Whisper é partilhada através do volume Docker `whisper_models`, evitando que cada réplica transfira novamente centenas de megabytes da Internet ao arrancar.
4. **Porque foi feito assim:** Garante atomicidade no sistema de ficheiros (ou o ficheiro existe completo ou não existe) e poupa memória e largura de banda através de uma cache partilhada entre contentores.
5. **Onde está no código:** No microsserviço de vídeo em `Tools/video/video_processor.py` (métodos de limpeza no bloco `finally` e renomeação atómica) e nos testes de integração em `Tools/video/tests/test_video_effects.py`.
- **Exemplo concreto:** P-03 mediu um pico de **271,6% de CPU** e **1,85 GiB de RAM** num vídeo de 60 s com brilho e verificou o regresso dos consumidores após reiniciar RabbitMQ. No seguimento QS-03, um trabalho de legendagem ativo retomou após reiniciar o worker ou o broker, ficou descarregável e deixou zero novos artefactos parciais. [Registo dos ensaios](sessoes/2026-11-23-recuperacao-e-polling.md)
- **Como foi testado:** Execução de 76 testes em pytest com `.venv/bin/python -m pytest -q Tools/video/tests` e inspeção manual do volume Docker `image_data`.

---

#### Incremento U-01 — Snapshot Persistente do Estado da Execução no MongoDB
`[FEITO E VERIFICADO]`

1. **O que era o problema:** O estado do processamento de um projeto existia unicamente em mensagens voláteis do RabbitMQ e na memória dos navegadores abertos. Se o utilizador recarregasse a página, o backend não tinha nenhum registo persistido que dissesse se o projeto estava a correr ou em que percentagem ia.
2. **O que acontecia antes:** O documento do projeto no MongoDB guardava apenas a lista de imagens e a versão do projeto. Não existia nenhum campo a indicar o estado da execução corrente.
3. **O que acontece agora:** Foi criado no esquema do projeto em MongoDB um subdocumento obrigatório chamado `processingRun`. Este registo guarda o `runToken` (identificador único da execução), o `state` (`running`, `completed`, `failed` ou `cancelled`), as datas de início e término (`startedAt`, `finishedAt`), e um mapa com o progresso percentual monotónico de cada vídeo individual (`videoProgress`).
4. **Porque foi feito assim:** Ao guardar o estado na base de dados principal (MongoDB), qualquer instância do frontend ou qualquer novo separador do navegador pode saber exatamente em que estado o projeto está, bastando consultar a base de dados.
5. **Onde está no código:** No modelo Mongoose do projeto em `projects/models/project.js` (esquema `processingRunSchema`) e no controlador `projects/controllers/project.js:startProcessingRun`.
- **Exemplo concreto:** Ao submeter o projeto `6b024d7c`, o documento em MongoDB passou a conter:
  `processingRun: { runToken: 1, state: "running", startedAt: ISODate("2026-11-22T02:03:40Z"), videoProgress: { "video1.mp4": 45 } }`.
- **Como foi testado:** Execução da suite de testes de modelo em `projects/tests/project-model.test.js` (14 testes aprovados).

---

#### Incremento U-02 — Validação e Gravação Monotónica de Eventos de Progresso
`[FEITO E VERIFICADO]`

1. **O que era o problema:** Mensagens de rede podem chegar fora de ordem. Se o trabalhador emitir um progresso de 40% e logo a seguir emitir 50%, uma lentidão na rede podia fazer com que a mensagem de 40% fosse processada depois da de 50%, fazendo a barra de progresso do utilizador regredir (andar para trás).
2. **O que acontecia antes:** O orquestrador não validava a monotonia das percentagens nem filtrava mensagens atrasadas pertencentes a execuções anteriores que já tinham sido canceladas.
3. **O que acontece agora:** Quando chega uma mensagem de progresso à fila `project_queue`, o orquestrador verifica rigorosamente três coisas: (1) o `token` da mensagem coincide com o `runToken` da execução ativa, (2) o estado atual é `running` e (3) a nova percentagem é estritamente maior ou igual à percentagem que já estava guardada na base de dados. Se uma mensagem trouxer um valor inferior ou se pertencer a um token antigo, a mensagem é confirmada no RabbitMQ e imediatamente descartada sem atualizar a base de dados nem emitir eventos espúrios.
4. **Porque foi feito assim:** A garantia de monotonia impede que a interface do utilizador trema ou mostre valores inconsistentes devido a oscilações normais de latência em sistemas distribuídos.
5. **Onde está no código:** Em `projects/utils/processBatch.js` e no manipulador de mensagens de RabbitMQ em `projects/utils/rabbit_mq.js` (função que processa as mensagens vindas dos trabalhadores).
- **Exemplo concreto:** Se o vídeo `mandela.mp4` estiver com 65% registado no MongoDB e chegar uma mensagem atrasada com 60%, o orquestrador ignora o valor 60% e mantém os 65%. Quando chega a mensagem de 70%, o registo é atualizado atómicamente no MongoDB e reencaminhado via WebSocket para o navegador.
- **Como foi testado:** Testes unitários em `projects/tests/process-batch.test.js` (24 testes aprovados simulando mensagens atrasadas e fora de ordem).

---

#### Incremento U-03 — Rota HTTP Segura de Consulta do Estado de Execução
`[FEITO E VERIFICADO]`

1. **O que era o problema:** O frontend precisava de uma forma fiável de obter o estado atual do processamento logo ao abrir a página, sem depender exclusivamente da chegada de mensagens WebSocket.
2. **O que acontecia antes:** Não existia nenhum ponto de acesso (*endpoint*) na API para consultar o progresso de um projeto. A interface dependia unicamente de estar ligada à sala de WebSockets no exato momento em que os eventos eram transmitidos.
3. **O que acontece agora:** Foi criada a rota autenticada `GET /api-gateway/projects/:owner/:project/processing-status`. Esta rota devolve uma projeção limpa do subdocumento `processingRun`. O proprietário do projeto tem acesso direto; um utilizador convidado só consegue aceder se apresentar no cabeçalho um código de partilha válido (`shareId`) com permissão de leitura ou edição. Utilizadores sem permissão recebem o código HTTP `403 Forbidden`.
4. **Porque foi feito assim:** Segue o princípio arquitetural REST e permite o padrão de *polling* de segurança: o cliente faz uma pergunta direta à API assim que ganha foco ou reconecta a ligação à rede.
5. **Onde está no código:** Em `projects/routes/projects.js` (definição da rota `processing-status`), com reencaminhamento no ficheiro `apiGateway/routes/projects.js` e cliente de dados em `frontend/src/features/projects/api/processing-status.ts`.
- **Exemplo concreto:** Ao enviar um pedido HTTP com token JWT válido para `/api-gateway/projects/user1/projA/processing-status`, o servidor responde em 12 milissegundos com:
  `{ "runToken": 1, "state": "running", "startedAt": "2026-11-22T02:03:40.000Z", "videos": { "mandela.mp4": { "percent": 72 } } }`.
- **Como foi testado:** 28 testes de rota executados em `projects/tests/projects-routes.test.js`, validando respostas com sucesso, rejeição com erro 403 e projetos sem execuções ativas.

---

#### Incremento U-04 — Painel Não Bloqueante e Reconciliação no Cliente (Frontend)
`[FEITO E VERIFICADO]`

1. **O que era o problema:** A janela modal cobria a totalidade do ecrã e impedia a navegação. Ao sair da página ou recarregar com a tecla F5, o utilizador perdia o controlo visual do processamento.
2. **O que acontecia antes:** A página exibia uma barreira cinzenta intransponível. Mudar de página significava perder o indicador de progresso para sempre.
3. **O que acontece agora:** A janela cinzenta bloqueante foi completamente eliminada. Quando o utilizador clica em "Apply", a página do projeto em processamento fica em modo de leitura protegida, mas o utilizador pode livremente navegar para a lista de projetos, abrir o projeto B e trabalhar normalmente. Na parte inferior de todo o dashboard foi introduzida uma barra fixa (*painel global de processamento*). Esse painel mostra o nome do projeto em curso, a percentagem atual, um botão para regressar ao projeto de imediato e um botão para cancelar o lote. Adicionalmente, o identificador do projeto ativo é memorizado no `sessionStorage` do navegador: se o utilizador pressionar F5 ou fechar e reabrir a janela, o frontend faz uma chamada à rota da U-03 e restaura a barra de progresso no mesmo milissegundo.
4. **Porque foi feito assim:** Separa o ciclo de vida da interface visual do ciclo de vida das tarefas no servidor. O utilizador recupera total liberdade de movimentos sem perder a visibilidade dos seus trabalhos longos.
5. **Onde está no código:** Em `frontend/app/dashboard/[pid]/page.tsx`, `frontend/components/dashboard-processing-status.tsx`, e no ficheiro de lógica pura de reconciliação `frontend/lib/processing-status.ts`.
- **Exemplo concreto:** O utilizador coloca um vídeo longo a processar no projeto A. De seguida, clica no menu, abre o projeto B e altera o brilho de uma foto. Na parte inferior do ecrã, o painel mantém a indicação "Processing project A... 68%". O utilizador clica em "Open project" e a interface transita suavemente de volta para o projeto A.
- **Como foi testado:** Testes unitários com Node.js em `frontend/tests/processing-status.test.mjs` (7 testes aprovados) e bateria de ensaios completos no navegador Google Chrome / Chromium através da ferramenta de automação Playwright (`evaluation/evidence/phase2-final-2026-11-22/usability/`).

---

### 4.5 Defeitos Encontrados nas Validações (F1 a F9) e o Seu Estado

Durante a auditoria profunda realizada a 21 de novembro de 2026 (`docs/fase-2-auditoria.md`), foram formalmente catalogados 9 defeitos e vulnerabilidades (designados de F1 a F9). Abaixo apresenta-se o estado e resolução de cada um:

| Código | Dimensão e Severidade | Descrição do Problema | Estado e Resolução |
|---|---|---|---|
| **F1** | Orquestração — **Crítica** | Eliminação indevida de resultados em finalizações simultâneas de lotes de vídeo concorrentes. | **[FEITO E VERIFICADO]** Corrigido no commit `7757555`. A função `discardRunResults` valida a persistência antes de apagar qualquer ficheiro. |
| **F2** | Estado Persistente — **Alta** | Função `updateIfVersion` regravava o documento completo, arriscando repor versões antigas após concorrência. | **[FEITO E VERIFICADO]** As escritas de progresso e estado usam operadores atómicos do MongoDB (`$set`), mantendo a integridade. |
| **F3** | Progresso entre Réplicas — **Alta** | Consulta do MongoDB exigia que a data da mensagem fosse mais recente que a data global do lote, descartando atualizações legítimas de vídeos mais lentos. | **[FEITO E VERIFICADO]** Monotonia condicionada individualmente por identificador de vídeo em `projects/models/project.js`. |
| **F4** | Identidade e Autorização — **Alta** | Serviço interno `projects` confiava em cabeçalhos HTTP sem validação estrita de assinatura JWT em todas as rotas internas. | **[FEITO MAS POR CONFIRMAR]** Mitigado na rota `processing-status` com verificação de permissões do dono e links de partilha. Revisão global de portas do Compose continua como dívida técnica. |
| **F5** | Cliente e Permissões — **Alta** | Recarregamento com a tecla F5 abria resultados antigos prematuramente; botões de cancelamento ficavam visíveis a utilizadores que eram apenas leitores. | **[FEITO E VERIFICADO]** Corrigido na sessão de fecho da Fase 2 (`docs/sessoes/2026-11-22-fecho-fase-2.md`). Distingue snapshot inicial de transição observada e oculta botões a quem não tem permissão de escrita. |
| **F6** | Instrumento de Avaliação — **Alta** | O script de teste `evaluation/run_scenario.py` esperava pelo fim do vídeo A antes de olhar para o vídeo B, inflacionando artificialmente a duração de B quando B acabava primeiro. | **[FEITO E VERIFICADO]** Script reescrito para observar A e B em simultâneo em cada ronda de amostragem (`evaluation/run_scenario.py#L210-L245`). |
| **F7** | Mensageria e Resiliência — **Alta** | As ferramentas de imagem usam confirmação automática imediata (`auto_ack=True`). O consumidor de `projects` perdia a subscrição após reiniciar RabbitMQ. | QS-03 verificou a reconexão automática de `projects` e a reentrega do trabalho de vídeo. A confirmação automática das ferramentas de imagem continua como dívida. |
| **F8** | Quotas e Perfis — **Média** | O cancelamento devolvia operações avançadas de imagem e retinha as operações de vídeo. | Corrigida e verificada em separado com contas gratuitas. As campanhas dos requisitos escolhidos usaram contas premium. |
| **F9** | Ambiente e Empacotamento — **Média** | O ficheiro `frontend/Dockerfile` instalava o gestor Bun e dependências antes de copiar o ficheiro de bloqueio `bun.lockb`. | **[FEITO E VERIFICADO]** O build de produção foi gerado e validado localmente, gerando as 13 páginas estáticas sem falhas de compilação. |

---

### 4.6 Resultados das Medições Numéricas: Linha de Base vs. Solução Final

Todas as medições foram executadas no mesmo computador físico (processador Intel Core i7-13650HX de 20 núcleos, 32 GB de RAM, sistema operativo Linux x86_64, Docker Engine 29.9.3). Os números apresentados são reais, extraídos diretamente dos relatórios de teste gerados pela ferramenta oficial (`evaluation/summarize.py` e logs da sessão de 22/11/2026).

#### Tabela Resumo: Eficiência de Desempenho (Capacidade de Vídeo)
A medição compara a execução do projeto A (vídeo de 177 s com legendagem) e do projeto B (3 vídeos com brilho submetidos 1,5 s após A).

| Métrica Avaliada | Linha de Base Oficial (1 Réplica) | Solução Final (2 Réplicas) | Meta Estabelecida | Veredito |
|---|---:|---:|---:|:---:|
| **Tempo de espera de B (`b_wait_seconds`)** | **61,727 s** | **0,113 s** | **≤ 15,0 s** | **Superado com distinção** |
| Duração total do projeto B (`b_duration_seconds`) | 68,374 s | 9,676 s | Informativa | Redução drástica (-85,8%) |
| Duração do projeto A (`a_duration_seconds`) | 63,888 s | 80,961 s | Informativa | Aumento de 26,7% (partilha de CPU) |
| Tempo total do lote (*makespan*) | 69,925 s | 80,961 s | Informativa | Aumento ligeiro por concorrência |
| Máximo de mensagens na fila em espera (`max_ready`) | 3 | 2 | Informativa | Fila esvazia mais rapidamente |
| Máximo de mensagens em processamento (`max_unacked`)| 1 | 2 | 2 réplicas | 2 trabalhadores em paralelo |
| Pico de utilização de CPU agregada | 830,810% | 738,700% | Informativa | Distribuição eficiente por núcleos |
| Pico de consumo de memória RAM | 3 050 500 522 B (~3,05 GB) | 4 288 882 758 B (~4,29 GB) | Informativa | Custo previsto (+1,24 GB de RAM) |

*Explicação dos números de capacidade:* Quando o sistema tinha apenas 1 réplica, o projeto B ficava 61,727 segundos parado na fila à espera que o vídeo A libertasse o trabalhador. Na solução final com 2 réplicas, o trabalhador 2 pegou no projeto B em apenas **0,113 segundos** após a sua submissão. O projeto B terminou em apenas 9,676 segundos. Em contrapartida, o projeto A demorou mais tempo a terminar (passou de 63,888 s para 80,961 s) porque os dois trabalhadores passaram a disputar os mesmos núcleos do processador da máquina anfitriã, e a memória RAM total subiu de 3,05 GB para 4,29 GB. Este é o compromisso clássico de arquitetura (*trade-off*): ganhámos paralelismo e capacidade de resposta imediata à custa de maior consumo de recursos de hardware.

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
| Duração média da legendagem | 6,029 s | 6,153 s | Informativa | Desempenho equivalente (+0,12 s) |
| Pedidos HTTP à API por ensaio | 28 | 40 (inclui 8 de status) | Informativa | Tráfego total observado, incluindo navegação e reconexão |

Num ensaio complementar, um observador de status a 1 Hz acrescentou quatro pedidos e 1 048 bytes de corpo de resposta em quatro segundos, com mediana de 7,75 ms por pedido. [Medição de polling](sessoes/2026-11-23-recuperacao-e-polling.md)

*Explicação dos números de usabilidade:* Na versão antiga, o utilizador ficava bloqueado pelo modal. Se tentasse contornar navegando na barra de endereços, nunca mais conseguia ver o progresso de A (0 de 3 ações bem-sucedidas) e o recarregamento com a tecla F5 quebrava a aplicação. Na versão final, nos três ensaios formais (`trial-1`, `trial-2` e `trial-3`), o utilizador conseguiu executar as 4 ações sem qualquer impedimento (12 de 12), a recuperação após F5 e corte de rede foi perfeita (3 de 3), e a interface nunca exibiu um estado de conclusão antes de o servidor confirmar a gravação real dos ficheiros no disco.

---

### 4.7 O Que Foi Feito nos Exercícios 6 (Blocos 1 e 2) e 7

A equipa elaborou os trabalhos práticos intercalares que servem de alicerce ao relatório final:

1. **Exercício 6 (Bloco 1) — Identificação e Comparação de Padrões Arquiteturais (`docs/exercicios/RAS-exercicio_6_bloco1_SWdesign_template_PT.md`)**:
   - *O que foi feito:* Mapeou-se a arquitetura herdada, catalogando as evidências factuais do código (`EV-01` a `EV-10`) e as hipóteses técnicas (`H-01` a `H-05`). Identificaram-se os padrões existentes: Microsserviços e Arquitetura Orientada a Eventos no padrão global; e Filtros e Condutas (*Pipes and Filters*) combinados com Trabalhador Monolítico no processamento de vídeo. Formularam-se 4 alternativas arquiteturais de evolução (`ALT-1` a `ALT-4`).
   - *O que falta atualizar:* O ficheiro foi preenchido tendo como base o início da Fase 2. É necessário atualizar a secção de conclusões para refletir as decisões efetivamente implementadas e cruzar com os dados finais de medição.
2. **Exercício 6 (Bloco 2) — Cenários de Qualidade e Candidatos a RNF (`docs/exercicios/RAS-exercicio_6_bloco2_SWdesign_template_PT.md`)**:
   - *O que foi feito:* Caracterizaram-se formalmente os cenários de qualidade segundo a norma ISO/IEC 25010:2011: `QS-01` (para o candidato de Capacidade `CAND-1`) e `QS-02` (para o candidato de Usabilidade/Operabilidade `CAND-2`). Criou-se a matriz de compromissos (*trade-offs*) analisando o impacto cruzado das táticas sobre atributos como Fiabilidade, Portabilidade, Modularidade e Custo de Recursos.
   - *O que falta atualizar:* As métricas registadas no documento eram estimativas preliminares. Falta inserir na tabela de síntese os valores numéricos definitivos obtidos nos ensaios de 22 de novembro.
3. **Exercício 7 — Táticas Arquiteturais e Decisões de Design (`docs/exercicios/RAS-exercicio_7_taticas_SWdesign_template_PT.md`)**:
   - *O que foi feito:* Selecionaram-se e justificaram-se as táticas arquiteturais: `TAT-01` (escalação horizontal de réplicas com fila partilhada) para satisfazer `DA-1` (Decisão Arquitetural 1); e `TAT-04` (persistência assíncrona do estado com reconciliação no cliente) para satisfazer `DA-2` (Decisão Arquitetural 2). As táticas que introduziam novas funcionalidades aos utilizadores foram explicitamente rejeitadas para respeitar a diretriz docente de refactoring puro.
   - *O que falta atualizar:* Alinhar o texto com o código final que resolveu as falhas F1 e F5 e incorporar as conclusões das medições comparativas.

---

### 4.8 Estado do Relatório Final em Typst (`docs/src-doc-fase2-template/`)

O rascunho Typst foi preenchido e compilado para revisão. A árvore abaixo regista o estado anterior à sessão D-01/D-02. [Rascunho e instruções](src-doc-fase2-template/README.md)

```
Estado dos Capítulos do Relatório Typst
├── 00-historico-versoes.typ  ── [POR FAZER] (Tabela de histórico de versões por preencher)
├── 01-introducao.typ         ── [FEITO MAS POR CONFIRMAR] (Iniciado nos commits 9792d8d e 676e1c3; falta rever números finais)
├── 02-ambito-arquitetura.typ ── [FEITO MAS POR CONFIRMAR] (Preenchido no commit 51d0987 com diagramas SVG; falta integrar F1)
├── 03-padroes-atuais.typ     ── [POR FAZER] (Vazio no Typst; conteúdo existe em Ex. 6 Bloco 1)
├── 04-alternativas-matriz.typ── [POR FAZER] (Vazio no Typst; conteúdo existe em Ex. 6 Bloco 1)
├── 05-tradeoffs-cenarios.typ ── [POR FAZER] (Vazio no Typst; conteúdo existe em Ex. 6 Bloco 2)
├── 06-candidatos-rnf.typ     ── [POR FAZER] (Vazio no Typst; conteúdo existe em Ex. 6 Bloco 2)
├── 07-cenarios-taticas.typ   ── [POR FAZER] (Vazio no Typst; conteúdo existe em Ex. 7)
├── 08-decisoes-arquiteturais.typ ── [POR FAZER] (Vazio no Typst; conteúdo existe em Ex. 7)
├── 09-vista-antes-depois.typ ── [POR FAZER] (Falta gerar e incluir as figuras de arquitetura antes e depois)
├── 10-tradeoffs-medicao.typ  ── [POR FAZER] (Falta transcrever os dados das medições oficiais de 22/11)
├── 11-conclusoes.typ         ── [POR FAZER] (Capítulo vazio; conclusões por redigir)
├── 12-agentes-ia.typ         ── [POR FAZER] (Capítulo vazio obrigatório; reflexão crítica de IA ausente)
└── 99-anexos.typ             ── [POR FAZER] (Instruções de execução e glossário em falta)
```

- **Capítulo 12 (Utilização de Agentes de IA)**: O rascunho reúne as ferramentas identificadas nos exercícios e nas sessões. A equipa precisa de confirmar os modelos, skills e atribuições pendentes e registar a revisão humana.

---

## 5. O Que Falta Fazer (Por Ordem de Prioridade)

A tabela regista o plano de escrita original. P2 a P7 foram realizados para o rascunho. Faltam a revisão humana, a reprodução independente e a confirmação administrativa de P1.

| Prioridade | Tarefa a Realizar | Critério de Aceitação Objetivo | Dependência / Responsável |
|---|---|---|---|
| **P1** | Esclarecer Situação Administrativa da Entrega | Ter confirmação escrita (e-mail ou aviso) sobre a data limite de submissão do relatório e código da Fase 2. | Humano (Contacto urgente com os docentes da UC). |
| **P2** | Transcrever Exercícios para os Capítulos Typst (Caps. 3 a 8) | Copiar e adaptar o texto dos exercícios 6 (Blocos 1 e 2) e 7 para os respetivos ficheiros `.typ`, eliminando todos os marcadores `#preencher`. | Execução manual da equipa de escrita. |
| **P3** | Preencher Capítulo 10 com as Medições Finais | Inserir as tabelas de baseline vs. final (Capacidade e Usabilidade) em `10-tradeoffs-medicao.typ` com os números de 22/11. | Decisão editorial da equipa. |
| **P4** | Redigir Capítulo 12 (Utilização de Agentes de IA) | Preencher `12-agentes-ia.typ` com a tabela de tarefas, exemplos de código rejeitado da IA (F1) e reflexão crítica. | Decisão e reflexão dos membros da equipa. |
| **P5** | Gerar Diagramas Antes/Depois (Capítulo 9) | Criar as imagens comparativas de arquitetura (`images/vista_antes.png` e `images/vista_depois.png`) destacando as réplicas e o painel. | Execução de diagramação (PlantUML / Mermaid). |
| **P6** | Redigir Conclusões e Anexos (Caps. 11 e 99) | Preencher síntese final, ligação à Fase 3 e instruções de execução passo a passo em `11-conclusoes.typ` e `99-anexos.typ`. | Escrita final. |
| **P7** | Compilar e Validar PDF Final em Typst | Executar `typst compile main.typ` e verificar ausência de erros de formatação ou texto cortado. | Ambiente de desenvolvimento local. |

---

## 6. Riscos e Pontos Fracos Conhecidos (Com Franqueza)

Uma postura de engenharia de software rigorosa exige identificar sem reservas as fragilidades e limitações da solução atual:

1. **Risco de Conformidade com Prazos Docentes**: O prazo oficial de 20 de novembro de 2026 encontra-se ultrapassado. Não existe recibo no repositório. Este é o risco mais grave para a nota do projeto caso a equipa docente aplique penalizações por atraso.
2. **Variação da duração de A entre campanhas**: A duração média de A foi 63,888 s na baseline oficial, 85,048 s na repetição com uma réplica e 80,961 s no final. As revisões, imagens e instrumentos das campanhas diferiram. A variação de A não se pode atribuir isoladamente à escala. [Comparação](sessoes/2026-11-22-fecho-fase-2.md#final-capacity-and-same-instrument-baseline)
3. **Consumo Acrescido de Memória RAM**: A presença de duas instâncias do trabalhador de vídeo elevou o pico de consumo de memória de 3,05 GB para **4,29 GB de RAM** (um acréscimo de 1,24 GB). Em ambientes de alojamento na nuvem (*cloud*) com restrições orçamentais, isto representa custos operacionais acrescidos.
4. **Certificados TLS Internos Autoassinados e Expirados**: Os certificados criptográficos que protegem o tráfego HTTPS entre os microsserviços internos estão expirados e são ignorados na configuração do código (`rejectUnauthorized: false`). Embora aceitável em contexto de laboratório universitário, é uma vulnerabilidade grave para qualquer cenário de produção real.
5. **Segredos e Senhas Hardcoded no Repositório**: As chaves criptográficas (`JWT_SECRET_KEY`) e as senhas do MongoDB e RabbitMQ encontram-se escritas diretamente em texto claro nos ficheiros `docker-compose.yaml` e no código fonte. Qualquer pessoa com acesso ao repositório obtém credenciais de administrador.
6. **Âmbito da recuperação de vídeo**: QS-03 verificou um trabalho ativo em cada interrupção, com duas réplicas. A recuperação de outras cargas ou de falhas repetidas continua por caracterizar.
7. **Débitos de vídeo lançados antes da correção F8**. A versão anterior guardava apenas o débito das operações avançadas para reembolso. As reservas das novas execuções identificam a conta que pagou e o total debitado.

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
- **EV-01 a EV-10 (Evidências de Arquitetura)**: Fatos comprovados no código herdado da Fase 1 (registados no Exercício 6 Bloco 1), como por exemplo `EV-01` (existência de um único trabalhador de vídeo no Compose) e `EV-06` (presença de modal bloqueante no dashboard).
- **F1 a F9 (Falhas e Defeitos da Auditoria)**: Catálogo dos 9 pontos críticos identificados na auditoria de 21 de novembro (detalhados na secção 4.5).
- **ffmpeg / ffprobe**: Conjunto de ferramentas e bibliotecas de linha de comando em código aberto líderes de mercado para manipulação, conversão, descodificação e análise de formatos multimédia de áudio e vídeo.
- **H-01 a H-05 (Hipóteses de Arquitetura)**: Suposições técnicas formuladas no Exercício 6 Bloco 1 que necessitavam de validação empírica nos testes de laboratório.
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
  - `P-03`: Gestão de quotas de memória, limpeza de temporários `.part` e tolerância a falhas.
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

Em cumprimento escrupuloso da regra de integridade de não inventar factos, listam-se as informações que não foi possível comprovar por ausência de evidência física nos ficheiros do repositório:

1. **Estado Administrativo da Submissão Docente**: Não foi encontrado nenhum ficheiro de confirmação, recibo de entrega ou mensagem docente referente à submissão da Fase 2, cuja data limite oficial no documento `docs/fase-2-guidelines.md` era 20 de novembro de 2026. A equipa necessita de confirmar junto do corpo docente se o prazo foi formalmente estendido.
2. **Revisão do relatório Typst**: O rascunho foi preenchido e compilado. A equipa ainda precisa de rever o conteúdo e registar a reprodução independente das medições.
3. **Registo Humano da Utilização de Inteligência Artificial**: Não foram encontrados ficheiros de registo onde os elementos do grupo tenham anotado individualmente que prompts exatos de IA foram submetidos, que blocos de código foram gerados por IA e quais foram rejeitados por intervenção humana (lacuna necessária para preencher a tabela de prestação de contas do capítulo 12).
4. **Custo de polling sob outras cargas**: O ensaio complementar mediu o custo HTTP de um observador a 1 Hz. O custo em CPU e memória e o comportamento com múltiplos observadores ficam por medir.
