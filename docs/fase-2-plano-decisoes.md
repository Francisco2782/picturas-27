# Fase 2 — folha de decisão

## Objetivo da Fase 2

Escolher dois requisitos não funcionais, melhorar o código através de refactoring e
provar a melhoria com medições:

**requisito → baseline → refactoring → medição final**

Não devemos acrescentar funcionalidades novas.

## O que temos de decidir na reunião

Preencher esta tabela para cada requisito escolhido.

| Decisão | NFR 1 — Capacidade de processamento de vídeo | NFR 2 — Usabilidade durante o processamento |
| --- | --- | --- |
| Nome do requisito | Eficiência de desempenho — capacidade | Usabilidade — operabilidade |
| Classificação ISO/IEC 25010:2011 | Eficiência de desempenho / capacidade | Usabilidade / operabilidade |
| Problema atual no sistema | Existe uma réplica de `video_tool`, com `prefetch_count=1`, que processa cada pipeline de vídeo de forma síncrona. A transcrição CPU-bound de legendas ocupa esse worker e atrasa os restantes trabalhos na `video_queue`. | O dashboard apresenta uma sobreposição de processamento bloqueante e mantém o estado no componente. A navegação fica limitada e um refresh perde o estado visível do trabalho. |
| O que vamos medir? | Métrica principal: `b_wait_seconds` (início do primeiro log `brightness` menos a submissão do projeto B). Também duração A/B, makespan, máximos da fila pronta/não confirmada e picos de CPU/RAM por worker e agregados. | Interações concluídas durante o processamento ativo (0–4 por ensaio e percentagem em três ensaios), recuperação após navegação (0–3) e após refresh (0–3). Registar ainda duração/resultado das legendas e pedidos de estado/API e eventos de progresso duplicados/obsoletos. |
| Unidade da medição | Segundos; mensagens para máximos da fila; CPU em percentagem; memória em bytes; número de réplicas. | Número de interações e recuperações bem-sucedidas e percentagem. Pedidos/eventos em contagem e duração em segundos. |
| Como vamos medir? | Cenário A/B fixo e automatizado: A processa o vídeo de fala com `subtitles`; B processa dois MP4 de 10 s e um MOV de 6 s com `brightness`. Projetos novos, A submetido 1–2 s antes de B. Uma amostra de aquecimento e três medições válidas. Baseline em `phase2-base` com uma réplica; final com duas. Agregar logs e amostras de todas as réplicas. | Chromium, viewport 1280×720 e conta premium. Um aquecimento e três ensaios válidos com projetos A/B independentes e o mesmo vídeo de 10 s com fala. Durante o job de legendas em A: abrir B, usar a toolbar sem iniciar outro processamento, regressar a A e confirmar o estado; depois verificar recuperação após navegação e refresh. Registar separadamente cada resultado. |
| Valor da baseline | Ainda por medir oficialmente em `phase2-base`. Evidência local provisória: média de 65,7 s (intervalo 62,6–70,1 s), não aceite como baseline oficial. | Ainda por medir em `phase2-base`; não substituir por estimativas baseadas apenas na inspeção do código. |
| Valor-alvo | Média final de `b_wait_seconds` ≤ 15 s em três medições válidas. | 12/12 interações; recuperação correta em 3/3 navegações e 3/3 refreshes, sem estado ativo obsoleto nem falsa conclusão. |
| Mínimo aceitável | Média final de `b_wait_seconds` ≤ 30 s em três medições válidas. | Pelo menos 3/4 interações em cada ensaio; recuperação correta em 3/3 navegações e 3/3 refreshes; nenhuma falsa conclusão. |
| Refactoring proposto | Executar duas réplicas limitadas do worker existente na mesma `video_queue`, cada uma com `prefetch_count=1`. Manter uma réplica por omissão, o contrato de dispatch e o pipeline integral por vídeo. Não criar uma fila separada para legendas. | Persistir no serviço `projects` o estado mínimo recuperável de cada execução; validar progresso por token e encaminhá-lo pelo `project_queue` existente; disponibilizar snapshot autorizado e mostrar o estado num painel não bloqueante partilhado entre páginas. Preservar o cancelamento apenas se já existir. |
| Testes de regressão | Harness: zero/uma/duas réplicas, IDs que mudam, logs por réplica, amostras ausentes/malformadas e agregação alinhada. Aplicação: lotes concorrentes, conclusão fora de ordem, resultados únicos, tokens e falhas/limpeza; suites de projetos e `Tools/video`. | Transições, permissões, token, progresso monotónico, duplicados/atrasados, refresh/navegação/reconexão e estados terminais; regressões de imagem/vídeo, frontend e cancelamento se suportado. |
| Riscos/efeitos secundários | Maior utilização de CPU/RAM, pressão na fila e volume partilhado, reinícios/OOM e conclusão fora de ordem. Registar recursos por worker e agregados, reinícios, falhas e execuções inválidas; verificar commits e limpeza. | Escritas/leitura adicionais de estado, eventos fora de ordem ou duplicados, estados presos após falha e exposição indevida do estado. Validar idempotência, precedência terminal, autorização e reconciliar snapshot/socket por token e timestamp. |

## Opções sugeridas no guideline

Escolher duas opções distintas. Estas são apenas sugestões; a equipa pode propor
outras, desde que consiga medi-las.

### Opção A — Fiabilidade do processamento

**Requisitos relacionados:**

- `REQ-VID-FAIL-004` — o sistema deve garantir que uma falha interna a meio do
  processamento não faz perder o trabalho de edição. No MVP, depois de uma falha
  interna, o trabalho deve voltar a ser processado.
- `REQ-VID-EDIT-012` — o sistema deve manter a taxa de sucesso da edição de vídeos
  válidos acima de um limiar: pelo menos 95% no MVP e 99,5% no alvo final.

**Problema encontrado:** os processadores de imagem usam confirmação automática da
mensagem em [rabbit_mq.py](../Tools/utils/rabbit_mq.py). Se o serviço cair depois de
receber uma mensagem, o trabalho pode perder-se. O worker de vídeo já confirma a
mensagem apenas no fim.

**Possível pergunta de investigação:** depois de uma falha do worker, o sistema
recupera automaticamente todos os trabalhos?

**Decisões que a equipa terá de tomar:**

- confirmação manual apenas nas ferramentas de imagem ou em todos os workers;
- momento exato da confirmação;
- número máximo de tentativas;
- tratamento de mensagens que falham repetidamente;
- prevenção de resultados duplicados;
- teste apenas com imagens ou também com vídeos.

**Medições possíveis:**

- percentagem de trabalhos recuperados;
- número de mensagens perdidas;
- número de resultados duplicados;
- tempo até o trabalho terminar depois da recuperação.

### Opção B — Segurança

**Requisitos relacionados:**

- `REQ-VID-ACCESS-001` — apenas quem tem acesso ao projeto pode aceder aos vídeos e
  aos resultados.
- `REQ-VID-ACCESS-002` — os endereços de acesso e transferência devem ser temporários
  e não adivinháveis.
- `REQ-VID-ACCESS-003` — a biblioteca e as suas pastas devem estar restritas ao
  utilizador proprietário.

**Nota importante:** certificados internos e segredos no `docker-compose.yaml` são
problemas identificados no relatório da Fase 1 (`T-02` e `T-03`), mas não aparecem
como requisitos não funcionais específicos. Se a equipa escolher este tema, terá de
decidir se melhora os requisitos `REQ-VID-ACCESS-001` a `003` ou se define um novo
requisito específico para segredos e autenticação entre serviços.

**Problemas encontrados:**

- certificados internos expirados ou não validados;
- segredos escritos no repositório, incluindo configurações do Docker Compose.

**Possível pergunta de investigação:** conseguimos impedir ligações internas não
autenticadas e retirar os segredos do código versionado?

**Decisões que a equipa terá de tomar:**

- tratar segredos, certificados ou ambos;
- usar `.env`, Docker secrets ou outro mecanismo;
- quais os serviços que devem validar certificados;
- como distribuir e renovar certificados;
- como manter o arranque local reproduzível.

**Medições possíveis:**

- número de segredos encontrados no repositório;
- número de serviços que validam certificados;
- resultado de uma ligação com certificado inválido;
- resultado de uma ligação sem credenciais.

### Outras opções

Algumas correspondências já existentes são:

- **modularidade do vídeo** — `REQ-VID-EDIT-013` e `REQ-VID-EDIT-014`;
- **desempenho da edição** — `REQ-VID-EDIT-010`;
- **processamento paralelo** — `REQ-VID-EDIT-011`;
- **carregamento de vídeos** — `REQ-VID-SUBMIT-008`;
- **progresso da edição** — `REQ-VID-STATUS-003`;
- **usabilidade da pipeline** — relacionada com `REQ-VID-EDIT-004`,
  `REQ-VID-EDIT-005` e o problema `T-06`.

O guideline também sugere:

- usabilidade da criação de pipelines;
- modularidade do processamento de vídeo;
- elasticidade/desempenho;
- trabalho em segundo plano;
- eficiência do carregamento de ficheiros.

Se escolherem uma destas opções, devem preencher a tabela da primeira secção antes
de começar a alterar o código.

## Ordem de trabalho depois da decisão

1. Escolher os dois requisitos.
2. Escrever a tabela com métricas, baseline, alvo e mínimo aceitável.
3. Executar a medição inicial.
4. Decidir o refactoring e dividir tarefas.
5. Implementar sem alterar o comportamento funcional.
6. Executar os testes de regressão.
7. Repetir exatamente a medição inicial.
8. Comparar baseline, resultado final, alvo e mínimo aceitável.

## Informação de apoio

- O relatório da Fase 1 identifica fiabilidade e segurança como prioridades candidatas.
- O relatório indica o commit de partida `8006500`.
- Existem testes em [Tools/video/tests/](../Tools/video/tests/) e [projects/tests/](../projects/tests/).
- O guideline exige que a baseline seja medida antes do refactoring.
