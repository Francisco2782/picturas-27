# Do cenário de qualidade à tática arquitetural

*RAS · Design · Aula 6 (Bloco 2) e Aula 7 (Táticas)*

---

## Slide 1 · Do cenário de qualidade à tática arquitetural

Como transformar uma fragilidade do PicturRAS num requisito que se consegue medir — e como decidir a mudança de arquitetura que o resolve.

| Aula 6 | Aula 6 | Aula 7 | Aula 7 | Autónomo |
|---|---|---|---|---|
| **Fragilidade** | **Cenário** | **Tática** | **Decisão** | **Medição** |
| Evidência no código | Seis elementos + medida | A decisão de design | Alternativas e custos | Antes e depois |

*Fase 2 · refactoring, sem novas funcionalidades* — *Entrega **27.nov** · defesas a definir*

---

## Slide 2 · Enquadramento · Fase 2: Duas aulas que alimentam o relatório

Cada equipa escolhe **dois requisitos não funcionais distintos** e melhora-os por refactoring. O ciclo fecha-se com números, não com opiniões.

| Já feito | Aula 6 | Aula 7 | Autónomo | Entrega |
|---|---|---|---|---|
| **Bloco 1** | **Bloco 2** | **Exercício 7** | **Refactoring** | **27 nov** |
| Padrões, alternativas, matriz e evidências. | Trade-offs, **cenários de qualidade**, dois candidatos a RNF (`CAND-1/2`, `QS-nn`). | **Táticas**, decisões arquiteturais, efeitos colaterais, plano de medição. | Baseline, implementação, medição final, regressão. | Relatório e defesa (datas da defesa a definir). |

**RNF → quantificação → baseline → refactoring → medição final**

Os cenários definem **o que se mede**; as táticas decidem **o que se muda**.

*Mínimo a sair da Aula 6: dois candidatos distintos e dois cenários completos.* — *São a **entrada** da Aula 7.*

---

## Slide 3 · Parte A · Cenários de qualidade: «Rápido» e «fiável» não se testam

Um atributo de qualidade só passa a ser requisito quando se consegue dizer **quem faz o quê**, em que condições e como se verifica.

**Requisito vago**
- ✗ «O processamento de vídeo deve ser rápido.»
- ✗ «O sistema deve ser fiável.»
- ✗ «A aplicação deve aguentar muitos utilizadores.»

Não há estímulo, nem condições, nem unidade. Duas pessoas discordam e ninguém tem razão.

**Cenário de qualidade**

> *Um utilizador submete a legendagem de um vídeo enquanto outro aplica um efeito simples a um vídeo curto. O segundo trabalho termina em **X segundos**.*

Um estímulo, uma resposta, uma medida. Mede-se antes, muda-se, mede-se depois.

*Cenário = requisito de qualidade escrito de forma **testável**.* — *Bass, Clements & Kazman, Software Architecture in Practice*

---

## Slide 4 · Parte A · Cenários de qualidade: Anatomia: seis elementos

O mesmo molde serve para qualquer atributo. Muda o conteúdo, não a estrutura.

| # | Elemento | Descrição | Exemplos | Picturas (exemplo do projeto) |
|---|---|---|---|---|
| 1 | **Fonte do estímulo** | Quem ou o quê origina o evento | Utilizador, serviço, falha de hardware, atacante | O serviço `projects` |
| 2 | **Estímulo** | O evento a que o sistema reage | Um pedido, uma falha, uma carga, uma alteração | Publica as N mensagens do lote |
| 3 | **Artefacto** | A parte do sistema estimulada | Um serviço, uma fila, um módulo, o sistema todo | O publicador de mensagens |
| 4 | **Ambiente** | Em que condições | Operação normal, sobrecarga, modo degradado, arranque | Operação normal, broker acessível |
| 5 | **Resposta** | O que o sistema faz | Processa, deteta, recupera, recusa, regista | Todas as mensagens são publicadas |
| 6 | **Medida da resposta** | Como se verifica | Uma grandeza com unidade: ms, %, minutos, contagem | Tempo do lote (ms); ligações por lote |

*1 + 2 + 3 + 4 = **o problema*** — *5 + 6 = **o critério de aceitação***

---

## Slide 5 · Parte A · Cenários de qualidade: No Bloco 2, o cenário vai mais longe

Os seis elementos são o centro; à volta deles ficam a evidência que os justifica e o método que os mede.

| Passo 1 | Passo 2 | Passo 3 | Passo 4 | Passo 5 |
|---|---|---|---|---|
| **Evidência** | **Característica ISO/IEC 25010** | **Seis elementos** | **Escala e método** | **Valores** |
| Ficheiro e linha onde a fragilidade se vê (`EV-nn`). | E, quando aplicável, a subcaracterística. | Fonte, estímulo, artefacto, ambiente, resposta, medida. | Unidade, carga, ambiente e instrumento de medição. | Base, alvo e mínimo aceitável. |

> **Atenção ao passo 5.** Os valores só se fixam **depois da medição inicial** (baseline). Escrever «X» é correto; inventar «2 s» não é.

> **Prioridade.** Cada cenário ganha prioridade por **importância para os stakeholders** e por **dificuldade ou risco técnico**.

*Escala e método permitem repetir a medição «antes» e «depois».* — *Tarefa 5 do Bloco 2*

---

## Slide 6 · Parte A · Cenários de qualidade: Um bom cenário passa cinco testes

Usem esta lista antes de dar um cenário por fechado.

**Checklist**
- ✓ **Um estímulo e uma resposta** — não três cenários disfarçados de um.
- ✓ **Medida com unidade:** ms, %, minutos, número de ocorrências.
- ✓ **Ambiente explícito:** normal, sobrecarga, falha em curso.
- ✓ **Evidência no código** que mostra a fragilidade.
- ✓ **Sem funcionalidade nova:** melhora a qualidade, não acrescenta capacidades.

**Armadilhas frequentes**
- ✗ Adjetivos no lugar de medidas: «rápido», «robusto», «escalável».
- ✗ Medir o que não se consegue observar com os instrumentos disponíveis.
- ✗ Misturar atributos: desempenho e segurança no mesmo cenário.
- ✗ Preencher baseline, alvo e mínimo **sem ter medido**.
- ✗ Escolher o mesmo atributo duas vezes como se fossem dois requisitos.

*Pergunta de controlo: «como é que vou medir isto, e com que instrumento?»* — *Sem resposta, o cenário ainda **não está pronto**.*

---

## Slide 7 · Exemplo 1 · Eficiência de desempenho: Publicar o lote de mensagens de um projeto

| Campo | Conteúdo |
|---|---|
| **Característica** | ISO/IEC 25010 · Eficiência de desempenho → comportamento temporal e utilização de recursos |
| **Evidência** | `projects/utils/rabbit_mq.js:11-30` abre uma ligação e um canal AMQP **novos por cada mensagem** e fecha a ligação com um `setTimeout` de 500 ms |
| **Fonte do estímulo** | O serviço `projects`, ao despachar um projeto com vários vídeos |
| **Estímulo** | Publica as *N* mensagens do lote (uma por vídeo e por ferramenta) |
| **Artefacto** | Publicador de mensagens de `projects` |
| **Ambiente** | Operação normal, broker acessível |
| **Resposta** | Todas as mensagens são publicadas |
| **Medida da resposta** | Tempo de publicação do lote (ms) e número de ligações AMQP abertas por lote |
| **Escala e método** | ms por lote; ligações por lote. Lote de *N* com as amostras de `samples/video/`; mesmo ambiente antes e depois; *timer* no despacho e API `/api/connections` do RabbitMQ |
| **Valores base / alvo / mínimo** | A fixar após a baseline |

*Exemplo do enunciado do Bloco 2 — **ilustrativo, não o uses como candidato**.* — *Evidência relativa ao commit de partida*

---

## Slide 8 · Exemplo 2 · Fiabilidade → recuperabilidade: O worker de vídeo falha a meio de um lote

| Campo | Conteúdo |
|---|---|
| **Característica** | ISO/IEC 25010 · Fiabilidade → disponibilidade, tolerância a falhas e recuperabilidade |
| **Evidência** | `Tools/video/video.py:166-170` qualquer falha é respondida como erro e a mensagem é confirmada (*ack*) — **nunca é repetida**; uma só instância de `video_tool` (`prefetch=1`) |
| **Fonte do estímulo** | Falha interna do processo `video_tool` (erro do `ffmpeg`, *crash*) |
| **Estímulo** | O worker falha a meio do processamento de um vídeo de um lote |
| **Artefacto** | `video_tool` e a fila `video_queue` |
| **Ambiente** | Operação normal, lote com vários vídeos em curso |
| **Resposta** | O sistema recupera: o vídeo é concluído **sem saídas parciais e sem perder o pedido** |
| **Medida da resposta** | Tempo até ao vídeo estar concluído após a falha (min); pedidos perdidos; ficheiros parciais em `out` |
| **Escala e método** | minutos; contagens. Parar o contentor `video_tool` a meio de um lote de `samples/video/`; *timer* + inspeção do armazenamento; mesmo procedimento antes e depois |
| **Valores base / alvo / mínimo** | A fixar após a baseline |

*Segundo exemplo do enunciado do Bloco 2 — **ilustrativo**.* — *A **medida** tem três grandezas: tempo e duas contagens.*

---

## Slide 9 · Exemplo 2 · Esquema do cenário: O mesmo cenário, visto como sistema

**Entradas**
- **Fonte do estímulo:** Falha interna do processo `video_tool` (erro do `ffmpeg`, *crash*)
- **Estímulo:** O worker falha a meio do processamento de um vídeo de um lote

**Artefacto · o sistema:** `video_tool` e a fila `video_queue`

**Ambiente · condições:** Operação normal, lote com vários vídeos em curso

**Saídas**
- **Resposta:** Recupera: o vídeo é concluído **sem saídas parciais e sem perder o pedido**
- **Medida da resposta:** Minutos até concluir após a falha; pedidos perdidos; ficheiros parciais em `out`

*O estímulo **entra**, o sistema **reage**, a medida diz se a reação foi suficiente.* — *As condições mudam a resposta esperada.*

---

## Slide 10 · Parte A · Cenários de qualidade → Fase 2: Da fragilidade ao candidato a RNF

Vários cenários, dois escolhidos. A escolha tem de ser **justificada**, não intuitiva.

| 1 | 2 | 3 | 4 |
|---|---|---|---|
| **Evidência** | **Cenários** `QS-nn` | **Prioridade** | **Dois** `CAND` |
| Fragilidade concreta no código ou na arquitetura. | Um ou mais por fragilidade. | Importância × dificuldade e risco. | Distintos entre si, cada um com o seu `QS-nn`. |

| Justificar | Localizar | Antecipar |
|---|---|---|
| **Pertinência e complexidade** | **Origem da fragilidade** | **Efeitos colaterais** |
| Impacto real nos stakeholders; exigência técnica do refactoring e da avaliação. | Padrão global, padrão do vídeo ou interação entre ambos — condiciona o âmbito e o risco de regressão. | O que melhorar um requisito faz ao outro e aos restantes atributos. |

*Regra da Fase 2: o candidato tem de poder melhorar **sem funcionalidade nova**.* — *Os dois `QS-nn` seguem para a Aula 7.*

---

## Slide 11 · Parte B · Táticas arquiteturais: Uma tática é a ponte entre qualidade e arquitetura

> *Uma tática é uma decisão de design que influencia a resposta de um atributo de qualidade.*
> — Bass, Clements & Kazman

| Bloco 2 · Aula 6 | Decisão | Onde se realiza | Antes / depois |
|---|---|---|---|
| **Cenário de qualidade** | **Tática(s)** | **Elemento arquitetural** | **Resposta medida** |
| O estímulo e a resposta que se querem. | O que se decide fazer, e porquê. | Serviço, fila, módulo, configuração. | A mesma medição nos dois momentos. |

*Toda a tática tem um **preço** noutro atributo.* — *Tática = o *porquê* · Padrão = o *como**

---

## Slide 12 · Parte B · Táticas arquiteturais: Tática não é padrão — e não é funcionalidade

**Tática · o porquê**
A decisão que responde ao estímulo.
*Exemplo:* Introduzir concorrência, *retry*, reutilizar ligações.

**Padrão · o como**
A estrutura que costuma realizar uma ou mais táticas.
*Exemplo:* *Competing Consumers*, *Circuit Breaker*, *pool* de ligações.

Decide-se **primeiro a tática**; só depois se escolhe a estrutura que a concretiza.

**Regra de ouro da Fase 2**

| Classe | Descrição |
|---|---|
| **A** | **Refactoring puro.** O utilizador não vê diferença funcional. |
| **B** | **Alteração visível que é o objeto da melhoria** (ex.: explicar porque uma ferramenta não está disponível). Exige justificação. |
| **C** | **Funcionalidade nova.** Rejeitar ou redesenhar. |

**Teste rápido:** «Se retirar a tática, o utilizador perde alguma **capacidade** ou só perde **qualidade**?»

*Aceitáveis: **A** e **B** (com justificação) · **C** rejeita-se.* — *Anexo A do Ex. 7*

---

## Slide 13 · Desempenho · Mapa de táticas: Desempenho: pedir menos ou ter mais

Estímulo típico: eventos que chegam. Resposta: serem processados dentro de um limite de tempo. Mede-se em latência, *throughput*, *jitter* e utilização de recursos.

**Categoria 1 · Controlar a procura de recursos**
- **Gerir pedidos de trabalho** — filas, *throttling*, *back-pressure*
- **Limitar a resposta a eventos** — terminação antecipada
- **Priorizar eventos**
- **Reduzir a sobrecarga** — reutilizar ligações, menos intermediários
- **Limitar o tempo de execução**
- **Aumentar a eficiência** — algoritmos e estruturas melhores

**Categoria 2 · Gerir recursos**
- **Aumentar recursos** — máquina maior ou mais nós
- **Introduzir concorrência** — processar em paralelo
- **Replicar computação** — mais instâncias de um worker
- **Manter cópias de dados** — *caching*
- **Limitar o tamanho das filas**
- **Escalonar recursos** — prioridades e políticas

*Esquerda: **menos trabalho por pedido**. Direita: **mais capacidade** para o trabalho.* — *Apoio: `performance_tatics_PT.md`*

---

## Slide 14 · Desempenho · Exemplo de aplicabilidade (1/2): Cenário do Exemplo 1: que tática escolher?

Estímulo: *N* mensagens publicadas, cada uma com ligação AMQP nova. Resposta pretendida: menos tempo e menos ligações por lote.

| Tática (categoria) | Como produz a resposta | Já existe na base? | Classe |
|---|---|---|---|
| **Reduzir a sobrecarga: reutilizar ligações** (controlar a procura) | Uma ligação e um canal duradouros eliminam o *handshake* por mensagem | **Não** neste ficheiro | A |
| **Introduzir concorrência** (gerir recursos) | Publicar em paralelo | **Não** | A |
| **Agrupar mensagens** (controlar a procura) | Menos operações de rede | **Não**: cada mensagem é publicada individualmente (`projects/utils/processBatch.js:11`, base `0523102`) | A |

> **Porquê só a primeira?** A concorrência não reduz o custo *por mensagem* (mantém uma ligação por mensagem). Agrupar altera o contrato de mensagens que todos os consumidores partilham: risco de regressão alto.

> **Decisão:** reutilizar ligações. Alternativas rejeitadas: concorrência, agrupar mensagens e manter como está (sem melhoria).

*Classe **A**: o utilizador não vê diferença funcional.* — *Anexo B do Exercício 7 (exemplo trabalhado)*

---

## Slide 15 · Desempenho · Exemplo de aplicabilidade (2/2): Reutilizar ligações: antes e depois

**ANTES · uma ligação por mensagem**

| | | | | | |
|---|---|---|---|---|---|
| msg 1 | `connect` | `channel` | `publish` | `+500 ms` | `close` |
| msg 2 | `connect` | `channel` | `publish` | `+500 ms` | `close` |
| msg N | `connect` | `channel` | `publish` | `+500 ms` | `close` |

*N* ligações por lote. O custo de *handshake* repete-se *N* vezes.

**DEPOIS · ligação e canal duradouros**

| | | | |
|---|---|---|---|
| 1× | `connect` | `channel` | `reconexão` |
| msg 1 | `publish` | | |
| msg 2 | `publish` | | |
| msg N | `publish` | | |

1 ligação por lote. A reconexão passa a ser **necessária**.

**Consequência +:** Menos ligações por lote e menor latência de despacho.

**Consequência −:** Disponibilidade: uma ligação duradoura pode cair; tem de haver reconexão e tratamento de falhas.

**Medir:** Tempo do lote (ms) e ligações por lote, com o mesmo método antes e depois.

*Uma tática de **desempenho** cria a necessidade de uma tática de **disponibilidade**.* — *Pré-requisito: recuperar após falha*

---

## Slide 16 · Disponibilidade · Mapa de táticas: Disponibilidade: detetar, recuperar, prevenir

**Disponibilidade = MTBF / (MTBF + MTTR)**

Para subir: **evitar a falha** (aumentar o MTBF) ou **recuperar mais depressa** (reduzir o MTTR). O objetivo é que uma *falta* não chegue a ser uma *falha* visível.

| Detetar falhas | Recuperar | Prevenir falhas |
|---|---|---|
| **Ping/echo, heartbeat** | **Redundância** ativa, passiva, *spare* | **Transações** (tudo ou nada) |
| **Monitor** | **Retry**, tratamento de exceções | **Remoção de serviço** (*rejuvenation*) |
| **Deteção de exceções** | **Rollback**, degradação | **Modelo preditivo** |
| **Sanity checking**, *timestamp* | **Reconfiguração** | **Prevenção de exceções** |
| **Voting**, *self-test* | Reintrodução: *shadow*, reinício escalonado | Aumentar o conjunto de competências |

*Disponibilidade **alta** pede redundância ativa e *failover* automático; custa recursos e complexidade.* — *Apoio: `availability_tactics.md`*

---

## Slide 17 · Disponibilidade · Exemplo de aplicabilidade (1/2): Cenário do Exemplo 2: o que já existe na base?

Estímulo: o worker falha a meio de um vídeo. Resposta pretendida: recuperar sem perder o pedido e sem saídas parciais. Antes de propor, **verifica-se o que a base já faz**.

| Tática (categoria) | Evidência na base | Existe? | Classe |
|---|---|---|---|
| **Reentrega após falha** (recuperar) | *Ack* manual só no fim: se o worker morre, o RabbitMQ reentrega (`Tools/video/video.py:169-174`, base `0523102`) | **Sim** | A |
| **Escrita atómica** (prevenir · transações / rollback) | Escreve em `.part.mp4` e só então `os.replace`; apaga o parcial se falha (`Tools/video/video_processor.py:198-241`, base `0523102`) | **Sim** | A |
| **Reinício do processo** (recuperar · reinício) | `restart: on-failure` no `docker-compose.yaml` | **Parcial** | A |
| **Retry limitado de falhas transitórias** (recuperar) | Falha respondida como erro e *ack* — nunca repetida (`Tools/video/video.py:166-170`, base `0523102`) | **Não** | A |
| **Redundância passiva (*spare*)** (recuperar) | Uma só instância de `video_tool`, sem réplicas | **Não** | A |

*Melhorar uma tática **existente** é diferente de introduzir uma **nova**.* — *Tarefa 2 do Exercício 7*

---

## Slide 18 · Disponibilidade · Exemplo de aplicabilidade (2/2): Decisão: retry limitado das falhas transitórias

**Decisão `DA-n` (ilustrativa)**
**Repetir até *K* vezes antes de dar o vídeo por falhado**
Falhas transitórias passam a ser repetidas; só ao fim das tentativas o pedido segue como erro (ou para uma fila de mensagens mortas).
*Estrutura que a realiza:* Reentrega com contador + *dead-letter queue*

**Alternativas rejeitadas**
- **Réplica *spare*.** Duplica o uso de CPU e memória por um cenário que não exige disponibilidade contínua.
- **Timeout/heartbeat.** Deteta bloqueios, mas não recupera falhas explícitas.
- **Manter como está.** O pedido continua a perder-se.

**Consequência +**
Menos pedidos perdidos; recuperação sem intervenção do utilizador. Classe A.

**Consequência −**
Cada repetição ocupa o único worker (`prefetch=1`): **desempenho** piora. Mensagens «venenosas» exigem limite.

**Medir**
Minutos até concluir, pedidos perdidos e parciais em `out`, depois de parar o worker a meio.

*O ganho em **disponibilidade** tem custo em **desempenho**.* — *Exemplo ilustrativo — escolhe os **teus** cenários e táticas.*

---

## Slide 19 · Parte B · Trade-offs: Toda a tática tem um preço

A matriz de efeitos obriga a olhar para os atributos que a tática **não** tinha como alvo, incluindo o do outro cenário.

| Decisão | Desempenho | Disponibilidade | Recursos / Custo | Testabilidade |
|---|---|---|---|---|
| **Reutilizar ligações** (desempenho) | ↑ **melhora** | ↓ **degrada** (sem reconexão) | ↑ menos ligações | = **neutro** |
| **Retry limitado** (disponibilidade) | ↓ **degrada** (ocupa o worker) | ↑ **melhora** | = **neutro** | ↓ mais caminhos a testar |

**Interação entre as duas decisões**
Pré-requisito, sinergia ou conflito? Aqui, a tática de desempenho **exige** uma tática de recuperação (reconexão): pré-requisito.

**Pergunta para a defesa**
«Que atributo piora com a vossa decisão, quanto, e como o vão medir?»

*Performance ↔ disponibilidade · segurança ↔ usabilidade · desempenho ↔ modificabilidade* — *Tarefa 5 do Exercício 7*

---

## Slide 20 · Plano · O que fazem as equipas: O que sai de cada aula

**Aula 6 · Bloco 2 (Tarefas 4 e 5)**
- Justificar a matriz de trade-offs do Bloco 1.
- Escrever **cenários de qualidade** completos (seis elementos).
- **Priorizar:** importância × dificuldade e risco.
- Propor **dois RNF distintos** (`CAND-1/2`), cada um com o seu `QS-nn`, escala e método.

*Sai:* Dois candidatos e dois cenários completos

**Aula 7 · Exercício 7**
- **1 · 10 min** Copiar os dois cenários, sem os reescrever.
- **2 · 25 min** ≥ 3 táticas candidatas por cenário, classe A/B/C, existência na base.
- **3 · 25 min** Decisão `DA-n`: ≥ 2 alternativas e consequências.
- **4 · 10 min** Vista antes/depois.
- **5 · 20 min** Matriz de efeitos e plano de medição.

*Mínimo na aula:* Tarefas 1 a 3; as restantes podem terminar em autonomia

*Não inventem valores de **baseline**, alvo ou mínimo.* — *Documentem o uso de IA: aceitar, rejeitar, **validar**.*

---

## Slide 21 · Síntese: Tática transforma qualidade abstrata em decisão concreta

1. **Medir primeiro** — Sem cenário verificável não há tática defensável nem melhoria demonstrável.
2. **Verificar a base** — Ver o que já existe antes de propor. Melhorar não é o mesmo que introduzir.
3. **Pagar o preço à vista** — Declarar o que piora e como se mede. Refactoring, nunca funcionalidade nova.

**Referências e material de apoio**
- Bass, Clements & Kazman — *Software Architecture in Practice*, 4.ª ed. (disponibilidade, desempenho e restantes atributos)
- `Slides 9 Design Tactics` · `Apoio/Taticas/` (disponibilidade, desempenho, segurança) · Anexo A do Exercício 7
- Enunciados: `RAS-exercicio_6_bloco2_SWdesign_PT.md` · `RAS-exercicio_7_taticas_SWdesign_PT.md` e respetivos templates

*Cenário → Tática → Elemento arquitetural → Resposta medida* — *Entrega **27.nov***
