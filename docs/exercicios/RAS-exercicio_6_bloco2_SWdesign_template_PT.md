# 📝 Exercício 6 (Bloco 2) — Template de Trade-offs, Cenários de Qualidade e Candidatos a RNF
### Fase 2: Melhoria de Requisitos Não Funcionais do PictuRAS · Alimenta as secções de diagnóstico e de decisões arquiteturais do relatório da Fase 2

**Versão do template:** 1.1 · **Data:** 2026-11-04 · **Estado:** Em vigor · **Enunciado compatível:** 1.1

> **Como usar este template**
> - Segue o enunciado `RAS-exercicio_6_bloco2_SWdesign_PT.md` e **continua o template do Bloco 1 já preenchido** (`RAS-exercicio_6_bloco1_SWdesign_template_PT.md`). As secções 4 a 7 deste template correspondem, por ordem, aos pontos 4 a 7 do **Resultado Esperado**.
> - A numeração das secções (4 a 7) e dos IDs continua a do Bloco 1. Reutiliza os `EV-nn`, `H-nn` e `ALT-n` do Bloco 1 e acrescenta os novos ao registo da secção 2.6 desse documento.
> - Regista no relatório as **versões do enunciado e do template** que usaste (campo «Versões usadas» abaixo). O histórico de versões está no fim deste documento.
> - A estrutura final do relatório da Fase 2 será definida numa versão seguinte das diretrizes. Este template agrupa o conteúdo para o poderes copiar para o relatório sem retrabalho.
> - Substitui os textos entre chavetas `{...}`, apaga as linhas de ajuda (`>`) e os exemplos que não se aplicam.
> - **Distingue factos de hipóteses.** Um facto cita uma evidência (`EV-nn`); o que não tem evidência é uma hipótese (`H-nn`).
> - Convenções de IDs novos neste bloco: `QS-nn` (cenário de qualidade), `CAND-n` (candidato a RNF). Nunca reutilizes um ID eliminado.
> - O foco é a **extensão de vídeo**, **enquadrada no padrão global da solução**. Não analises o vídeo isoladamente.
> - Esta fase é de *refactoring*: os candidatos têm de poder ser melhorados sem acrescentar funcionalidades.
> - Se fizeres medições exploratórias, guarda os cenários, *scripts*, dados e ambiente para que sejam reprodutíveis e reutilizáveis como *baseline*.

---

**Equipa:** Grupo PL3-G5  
**Elementos:** Alice Soares (pg63920), João Azevedo (pg63981), Francisco Barros (pg65409), Samuel Ferreira (pg65441)  
**Commit de partida:** `0523102` (tag `phase2-base`), checkout `afb84e5` em `picturas-um/picturas-27`  
**Data da análise:** 2026-11-21  
**Versão deste documento:** v1.0  
**Versões usadas:** enunciado 1.1 · template 1.1  
**Versão do Bloco 1 usada como entrada:** v1.0

---

## 4. Trade-offs, cenários de qualidade e prioridades

### 4.1 Justificação detalhada das avaliações da matriz

> Parte da matriz do Bloco 1 (secção 3.3) e justifica as avaliações atributo a atributo.

| **Atributo** | **Justificação** | **Depende sobretudo de** (padrão global / padrão do vídeo / ambos) | **Evidência** |
|--------------|------------------|---------------------------------------------------------------------|---------------|
| **Eficiência de desempenho — comportamento temporal** | Na solução base, o tempo de resposta degrada-se exponencialmente para trabalhos que chegam após tarefas longas de legendagem, pois ficam retidos na fila. A introdução de consumidores concorrentes (ALT-1) desacopla o tempo de espera do tempo de serviço de outros utilizadores. Decompor em microsserviços (ALT-2) causaria uma sobrecarga temporal incomportável (múltiplas recodificações). | Padrão do vídeo | `EV-01`, `EV-03`, baseline oficial (`b_wait_seconds = 61,727 s`) |
| **Eficiência de desempenho — capacidade / elasticidade** | A base possui capacidade rígida e unitária (`prefetch_count=1`, réplica única), serializando todos os pedidos de vídeo. ALT-1 introduz elasticidade horizontal na fila de trabalho; ALT-2 escalaria por filtro mas sobrecarregaria o I/O do sistema. | Padrão do vídeo | `EV-01`, `EV-02`, `docker-compose.yaml` |
| **Fiabilidade — tolerância a falhas / recuperabilidade** | O vídeo atual tem elevada fiabilidade funcional por usar confirmação manual (`ack`) só no fim e escrita em ficheiros temporários `.part`. ALT-1 mantém esta garantia integralmente; as ferramentas de imagem do padrão global usam `auto_ack=True`, arriscando perda de trabalhos em caso de falha a meio. | Ambos | `EV-01`, `EV-07`, `Tools/video/video_processor.py` |
| **Manutenibilidade — modularidade / modificabilidade** | O padrão global em microsserviços oferece máxima modularidade (ferramentas isoladas). O padrão do vídeo afasta-se para um monólito de processamento (Pipeline Monolith) para poupar CPU/disco. ALT-1 mantém este compromisso sem alterar código do worker; ALT-2 maximizaria modularidade mas a um custo proibitivo de desempenho. | Padrão global | `EV-01`, `EV-04`, `Tools/video/effects.py` |
| **Segurança — confidencialidade e controlo de acessos** | Os dados e media mantêm-se protegidos no S3 e MongoDB, com acesso perimetral controlado por JWT no API Gateway. Contudo, certificados TLS internos com `rejectUnauthorized: false` representam uma dívida arquitetural herdada da infraestrutura global. | Padrão global | `EV-09`, `apiGateway/app.js` |
| **Usabilidade — operabilidade** | Na base, a interface bloqueava a totalidade do ecrã com um modal sobreposto durante o processamento em lote e perdia o estado visual em caso de recarregamento (*refresh*). Depende da persistência do estado no backend (`projects`) e de um painel não intrusivo no frontend. | Ambos | `EV-05`, `EV-06`, `EV-10` |

### 4.2 Cenários de qualidade para a extensão de vídeo

> Cada cenário tem os seis elementos. A **medida da resposta** deve ser definida por ti e ser verificável.

| **ID** | **Característica (ISO/IEC 25010)** | **Fonte do estímulo** | **Estímulo** | **Artefacto** | **Ambiente** | **Resposta** | **Medida da resposta** |
|--------|------------------------------------|-----------------------|--------------|---------------|--------------|--------------|------------------------|
| **QS-01** | Eficiência de desempenho — capacidade | Utilizador do sistema (cliente HTTP/API) | Submissão de um projeto B (3 vídeos curtos com efeito `brightness`) 1 a 2 segundos após a submissão de um projeto A (vídeo com fala longa com `subtitles`) | Fila `video_queue` (RabbitMQ) e microsserviço `video_tool` | Operação normal com múltiplos pedidos concorrentes em ambiente Docker | O processamento do projeto B inicia a execução sem aguardar pelo término da transcrição CPU-bound de A | Tempo de espera de B (`b_wait_seconds`): medido entre a submissão de B e o primeiro registo de log de processamento de brilho no worker. **Média final ≤ 15 s** (baseline: 61,7 s) |
| **QS-02** | Usabilidade — operabilidade | Utilizador autenticado (sessão premium no browser) | Utilizador navega para outro projeto, utiliza a barra de ferramentas, regressa ao projeto inicial e recarrega a página (*refresh*) durante o processamento ativo | Frontend SPA (Next.js Dashboard) e endpoint de estado de `projects` | Operação normal no Chromium (1280×720) durante execução ativa de legendas | A interface mantém-se completamente navegável sem bloqueios modais, recuperando o estado e percentagem reais após navegação e após recarregamento | Sucesso em 4/4 interações por ensaio (12/12 em 3 ensaios válidos); taxa de recuperação por navegação de 3/3 e por refresh de 3/3, com 0 falsas conclusões |
| **QS-03** | Fiabilidade — recuperabilidade | Falha interna de infraestrutura | Interrupção inesperada do contentor `video_tool` (ou reinício do broker RabbitMQ) durante o processamento de um lote de vídeo | Worker `video_tool`, RabbitMQ e serviço `projects` | Operação com falha transitória a meio de um lote | O sistema não perde o pedido (mensagem não é confirmada), recupera automaticamente a subscrição da fila e reprocessa sem deixar artefactos `.part` órfãos | 100% dos trabalhos concluídos com sucesso após restabelecimento; 0 ficheiros temporários parciais corrompidos no S3 / `image_data` |

**Priorização dos cenários**

| **ID** | **Importância para os stakeholders** | **Dificuldade / risco técnico** | **Prioridade** |
|--------|--------------------------------------|---------------------------------|----------------|
| **QS-01** | **Alta** — O bloqueio sistemático de utilizadores devido a trabalhos pesados de terceiros inviabiliza a usabilidade e a perceção de serviço do produto em ambiente multi-utilizador. | **Média** — Exige escala horizontal em Docker Compose e tratamento de condições de corrida de lote no orquestrador `projects`. | **1** |
| **QS-02** | **Alta** — O bloqueio de ecrã e a perda de visibilidade ao navegar ou fazer reload prejudicam criticamente a experiência do utilizador durante tarefas que demoram vários minutos. | **Média/Alta** — Requer persistência atómica no MongoDB, rota de consulta de estado protegida e reengenharia de componentes no React SPA. | **2** |
| **QS-03** | **Média** — Importante para robustez operacional, mas o worker de vídeo já dispõe de ack manual e escrita atómica que mitigam grande parte das falhas na base. | **Alta** — Tratamento complexo de reconexão de brokers e dead-letter queues sem funcionalidade nova. | **3** |

### 4.3 Atributos de qualidade por ordem de prioridade

> Com base nos cenários mais importantes.

1. **Eficiência de desempenho — capacidade (cenário QS-01)**: É o gargalo arquitetural mais crítico da base herdada. A serialização forçada (`prefetch_count=1`, instância única) impede qualquer utilização concorrente real do subsistema de vídeo, tornando o tempo de resposta inaceitável.
2. **Usabilidade — operabilidade (cenário QS-02)**: O processamento de vídeo é inerentemente assíncrono e demorado; prender o utilizador numa página modal e perder todo o contexto visual ao mudar de ecrã ou atualizar a página compromete a usabilidade básica da aplicação.
3. **Fiabilidade — recuperabilidade (cenário QS-03)**: Garantir que falhas de rede ou de contentores não originem trabalhos perdidos nem dados corrompidos no volume partilhado.

### 4.4 Pré-requisitos e efeitos colaterais entre atributos

| **Atributo A** | **Atributo B** | **Efeito** (pré-requisito, sinergia ou conflito) | **Razão / evidência** |
|----------------|----------------|--------------------------------------------------|-----------------------|
| Desempenho / Capacidade (QS-01) | Fiabilidade / Integridade de Dados | **Conflito / Risco** | Ter múltiplas réplicas a consumir da mesma fila pode levar a finalizações concorrentes fora de ordem no orquestrador `projects`, gerando condições de corrida na atualização do lote (falha F1 identificada na auditoria). |
| Desempenho / Capacidade (QS-01) | Utilização de Recursos (CPU / RAM) | **Conflito** | Duas réplicas do worker de vídeo a processar simultaneamente tarefas pesadas (FFmpeg + Faster-Whisper) aumentam o pico de consumo agregado de CPU (>800%) e memória (>3 GB no host). |
| Usabilidade / Operabilidade (QS-02) | Fiabilidade / Consistência | **Pré-requisito** | Para exibir o progresso e recuperar o estado em qualquer página/refresh de forma confiável, é pré-requisito indispensável ter um snapshot persistente e transições de estado atómicas no MongoDB (`processingRun`). |
| Usabilidade / Operabilidade (QS-02) | Desempenho / Carga no Backend | **Conflito menor** | O mecanismo de polling/reconciliação do cliente para atualizar o estado do snapshot adiciona pedidos HTTP periódicos à rota de status durante execuções ativas. |

### 4.5 Recomendações de melhoria à solução atual

| **Recomendação** | **Atributo(s)** | **Padrão a que se refere** (global / vídeo) | **Esforço** | **Risco de regressão** |
|------------------|-----------------|----------------------------------------------|-------------|------------------------|
| Executar duas réplicas limitadas de `video_tool` na fila partilhada `video_queue` com `prefetch_count=1` | Desempenho — Capacidade | Padrão do vídeo | Baixo | Baixo (com testes de concorrência) |
| Introduzir modelo de execução persistente (`processingRun`) no modelo do Projeto e validação de progresso monotónico | Usabilidade e Fiabilidade | Padrão global / vídeo | Médio | Baixo (preserva compatibilidade retroativa) |
| Substituir modal bloqueante no frontend por barra de progresso flutuante global no layout do Dashboard | Usabilidade — Operabilidade | Padrão global (UI) | Médio | Baixo (mantém lógica de cancelamento) |
| Corrigir condição de corrida no registo de `Process` e commit atómico de lote em `projects/utils/processBatch.js` | Fiabilidade / Integridade | Padrão global (orquestração) | Médio | Médio (crítico para integridade do lote) |

---

## 5. Candidatos a requisitos não funcionais da Fase 2

> **Dois** requisitos não funcionais **distintos**, classificados segundo a ISO/IEC 25010 (característica e, quando aplicável, subcaracterística). Têm de partir de fragilidades concretas da solução de base, com evidência. Cada um é especificado, implementado e avaliado por si, ainda que possam estar relacionados.

| **#** | **Característica / subcaracterística (ISO/IEC 25010)** | **Fragilidade na base (evidência)** | **Origem** (padrão global / padrão do vídeo / interação) | **Impacto nos stakeholders (pertinência)** | **Exigência técnica (complexidade)** | **Escala e método de medição (esboço)** | **Pré-requisitos / efeitos colaterais** |
|-------|---------------------------------------------------------|--------------------------------------|-----------------------------------------------------------|---------------------------------------------|---------------------------------------|------------------------------------------|----------------------------------------|
| **CAND-1** | Eficiência de desempenho — capacidade | Instância única do worker `video_tool` com `prefetch_count=1` serializa todos os pedidos; legendagem CPU-bound atrasa outros trabalhos em >60 s (`EV-01`, `EV-02`, `EV-03`). | Padrão do vídeo (processamento monolítico com consumidor único) | Crítico: utilizadores normais e premium sofrem atrasos gigantescos quando outro utilizador submete legendas. | Média: escalamento em Docker Compose, coordenação de lotes concorrentes e sincronização de escrita no orquestrador. | Escala: segundos de espera (`b_wait_seconds`). Método: cenário A/B com harness Python automatizado (`evaluation/run_scenario.py`). | Exige proteção de corrida no orquestrador `projects` (P-02); aumenta pico de CPU e RAM agregados no host. |
| **CAND-2** | Usabilidade — operabilidade | Overlay modal bloqueia toda a aplicação durante o lote; estado mantido apenas em memória volátil de componente React (`EV-05`). | Interação (orquestrador backend ↔ frontend React SPA) | Elevado: utilizador fica impossibilitado de trabalhar noutros projetos e perde a visibilidade se navegar ou recarregar a página. | Média/Alta: persistência atómica no MongoDB, criação de rota autorizada de estado e reconciliação React/WebSocket. | Escala: número e taxa de interações concluídas (0–4) e taxa de recuperação após navegação e refresh (0–3). Método: ensaio instrumentado no Chromium. | Depende da persistência atómica de snapshots no backend; introduz tráfego adicional de polling na rota de status. |

### 5.1 Esboço de quantificação

> Esboça a **escala** e o **método de medição**. Os valores medidos na base, os valores-alvo e os valores mínimos aceitáveis **só são fixados após a medição inicial (*baseline*)**. Não os inventes agora.

| | **CAND-1 (Capacidade de Vídeo)** | **CAND-2 (Operabilidade e Recuperação)** |
|---|---|---|
| **Escala** (o que se mede e em que unidade) | Tempo de espera `b_wait_seconds` (em segundos): timestamp do primeiro log de processamento de brilho no worker menos o timestamp de submissão do lote B. | Contagem de ações bem-sucedidas durante o processamento ativo (0–4 por ensaio, total 0–12 em 3 ensaios) e taxa de recuperação após navegação (0–3) e após refresh (0–3). |
| **Cenário de medição** | Cenário automatizado A/B: Projeto A executa legendagem de vídeo com fala de 177s / 10s; Projeto B é submetido 1,5s depois com 3 vídeos (dois MP4 de 10s e um MOV de 6s com efeito `brightness`). | Cenário de utilizador no browser com conta premium: Projeto A inicia legendas num vídeo com fala de 10s; utilizador abre Projeto B, manipula a toolbar, regressa a A, navega e atualiza a página. |
| **Carga** | 2 projetos concorrentes, total de 4 vídeos em simultâneo com filtros diversificados (IA + filtros de cor). | 1 utilizador ativo, 2 projetos em alternância durante janela ativa de processamento de ~10 a 60 segundos. |
| **Ambiente** | Docker Compose no host de avaliação, RabbitMQ com filas duráveis, 1 réplica (baseline) vs 2 réplicas (final). | Chromium versão recente, viewport fixo de 1280×720, ligação WebSocket ativa e tráfego HTTPS local (:8080). |
| **Instrumento** | `evaluation/run_scenario.py` e `evaluation/summarize.py` com recolha de logs e Docker stats em intervalos de 1s. | Instrumentação manual e automatizada com registo de timestamps, eventos WebSocket e observação de rede DevTools. |
| **Valor medido na base (*baseline* oficial)** | **Média: 61,727 s** (mínimo 61,390 s, máximo 61,936 s em 3 execuções válidas). | **6/12 interações (50%)**; navegação: **0/3**; refresh: **0/3** (bloqueio total por overlay). |
| **Valor-alvo** | **Média final ≤ 15,0 s** em 3 execuções válidas. | **12/12 interações (100%)**; navegação: **3/3**; refresh: **3/3**; 0 falsas conclusões. |
| **Valor mínimo aceitável** | **Média final ≤ 30,0 s** em 3 execuções válidas. | **≥ 3/4 em cada ensaio**; navegação: **3/3**; refresh: **3/3**; 0 falsas conclusões. |

### 5.2 Relação entre os dois candidatos

Os dois candidatos incidem sobre o ciclo de vida do processamento assíncrono sob perspetivas complementares: CAND-1 aborda o **lado do servidor e do processamento** (reduzindo a retenção na fila através de concorrência horizontal), enquanto CAND-2 aborda o **lado do cliente e da experiência do utilizador** (desacoplando a navegação do utilizador do tempo de execução do lote). Não existe conflito direto entre eles: a melhoria da operabilidade (CAND-2) é especialmente vantajosa quando os lotes demoram mais tempo, e o aumento de capacidade (CAND-1) reduz a duração global do processamento sem invalidar a necessidade de um acompanhamento não bloqueante.

### 5.3 Evidência exploratória (se existir)

| **Descrição** | **Localização** (scripts, dados, resultados) | **Como repetir** |
|---------------|----------------------------------------------|------------------|
| Medição da baseline oficial de capacidade (CAND-1) | `evaluation/evidence/official-baseline-performance-2026-11-17/` | `python3 evaluation/summarize.py evaluation/evidence/official-baseline-performance-2026-11-17 --runs 3` |
| Medição da baseline oficial de usabilidade (CAND-2) | `evaluation/evidence/official-baseline-usability-2026-11-17/` | Inspeção dos ensaios registados em `run.json` e notas de teste no browser |
| Teste de concorrência e finalizações simultâneas | `projects/tests/batch-concurrency.test.js` | `node --test projects/tests/*.test.js` |
| Testes de reconciliação de estado no cliente | `frontend/tests/processing-status.test.mjs` | `node --test frontend/tests/processing-status.test.mjs` |

---

## 6. Conclusões e recomendações

**Adequação do padrão atual (global e do vídeo):**

A arquitetura de microsserviços orientada a eventos é plenamente adequada para as operações de negócio e gestão do PictuRAS. O padrão de *Pipeline Monolith* no worker de vídeo é tecnicamente correto e essencial para preservar o desempenho de I/O e a qualidade de imagem/áudio, evitando os custos proibitivos de uma decomposição em microserviços por filtro. Contudo, a execução com apenas uma réplica e o bloqueio da interface do utilizador eram fragilidades severas que foram diagnosticadas e ultrapassadas com sucesso pelos refactorings propostos.

**Sugestões de otimização:**

- Manter 2 réplicas do contentor `video_tool` por omissão ou implementar escalabilidade elástica limitada baseada na profundidade da fila `video_queue`.
- Consolidar a política de reconciliação de estado com debounce inteligente para diminuir o número de pedidos HTTP à rota `/processing-status`.
- Eliminar gradualmente a dívida técnica dos certificados TLS autoassinados internos através de uma autoridade de certificação local automatizada.

**Considerações para evolução futura:**

- Introdução de aceleração por hardware (GPU/NVENC/VideoToolbox) no contentor de vídeo para acelerar o Faster-Whisper e a transcodificação H.264.
- Partição de filas por prioridade de plano (e.g. fila dedicada para utilizadores premium vs fila comum para free/anónimos).

**Riscos para a preservação funcional e mitigação**

| **Risco** | **Funcionalidade afetada** (imagem / vídeo) | **Mitigação** | **Teste de regressão** (e.g., `Tools/video/tests`, `projects/tests`) |
|-----------|---------------------------------------------|---------------|-----------------------------------------------------------------------|
| Condição de corrida no orquestrador em lotes concorrentes (eliminação indevida de resultados ou registos pendentes) | Vídeo | Isolamento de tokens de execução, registo atómico de `Process` e limpeza seletiva de lotes inválidos | `projects/tests/` (28 testes Node.js, incluindo testes de concorrência de lote) |
| Dessincronização entre WebSocket e HTTP no frontend gerando estados de conclusão falsos ou regressões de progresso | Vídeo e Imagem | Reconciliação com progresso estritamente monotónico, ordenação por data de geração e verificação terminal | `frontend/tests/processing-status.test.mjs` (7 testes de lógica de cliente) |
| Perda de qualidade ou áudio na transcodificação concorrente | Vídeo | Manutenção dos parâmetros padrão de FFmpeg (H.264 + AAC) e testes unitários com amostras reais | `Tools/video/tests/` (76 testes PyTest cobrindo codecs, efeitos e áudio) |

---

## 7. Utilização de IA

> Documenta as ferramentas, as *skills*, as tarefas apoiadas e a validação feita pela equipa. A equipa é responsável por todo o conteúdo entregue.

| **Ferramenta / skill** | **Tarefa apoiada** | **Validação feita pela equipa** | **Onde está documentado** |
|------------------------|--------------------|----------------------------------|---------------------------|
| Gemini / Claude Code | Análise estática do código da base e identificação das evidências de concorrência e prefetch | Inspeção manual direta dos ficheiros de código-fonte (`video.py`, `processBatch.js`) e validação de linhas | `fase-2-implementacao.md` e Secção 2.6 deste documento |
| Scripts de automação Python / Node | Geração e execução do cenário de teste A/B (`evaluation/run_scenario.py`) | Verificação dos cálculos matemáticos de `b_wait_seconds` e auditoria dos ficheiros de logs e estatísticas Docker | `specs/002-nfr-improvement/spec.md` e `evaluation/README.md` |
| Modelo de testes | Criação da suite de testes de regressão de estado do cliente (`processing-status.test.mjs`) | Execução de `node --test` e revisão linha a linha das condições de teste e casos de fronteira | `frontend/tests/processing-status.test.mjs` e `fase-2-implementacao.md` |

---

## ✅ Lista de verificação antes de entregar o Bloco 2

- [x] O Bloco 1 está concluído e os seus IDs (`EV`, `H`, `ALT`) foram reutilizados, sem alterações (secção 4.1).
- [x] Todas as avaliações da matriz do Bloco 1 estão justificadas, indicando se dependem do padrão global ou do padrão do vídeo (secção 4.1).
- [x] Cada cenário de qualidade tem os seis elementos e uma medida da resposta verificável; os cenários estão priorizados (secção 4.2).
- [x] Os atributos estão ordenados por prioridade, com pré-requisitos e efeitos colaterais identificados (secções 4.3 e 4.4).
- [x] Há exatamente **dois** candidatos a RNF distintos, classificados pela ISO/IEC 25010, com origem, pertinência e complexidade (secção 5).
- [x] A escala e o método de medição estão esboçados e **nenhum valor de *baseline*, alvo ou mínimo foi inventado** (secção 5.1).
- [x] As medições exploratórias, se existirem, são reprodutíveis (secção 5.3).
- [x] Os riscos para a preservação funcional têm mitigação e testes de regressão associados (secção 6).
- [x] A utilização de IA está documentada e validada (secção 7).
- [x] As **versões do enunciado e do template** usadas estão indicadas no cabeçalho.

---

## Histórico de versões do template

> Esta secção documenta o template. **Não a copies para o relatório.** Esquema `major.minor`, igual ao do enunciado: a versão *major* muda quando mudam a estrutura ou os campos obrigatórios; a *minor* muda em clarificações e correções.

| Versão | Data | Alterações | Enunciado compatível |
|--------|------|------------|----------------------|
| 1.1 | 2026-11-04 | Adicionado o controlo de versões (linha de versão, campo «Versões usadas», item na lista de verificação e este histórico). | 1.1 |
| 1.0 | 2026-11-04 | Primeira versão: template do Bloco 2 (secções 4 a 7 e lista de verificação), criado a partir do template combinado do Exercício 6. | 1.0 |
