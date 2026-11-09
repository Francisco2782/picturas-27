# Fase 2 — folha de decisão

## Objetivo da Fase 2

Escolher dois requisitos não funcionais, melhorar o código através de refactoring e
provar a melhoria com medições:

**requisito → baseline → refactoring → medição final**

Não devemos acrescentar funcionalidades novas.

## O que temos de decidir na reunião

Preencher esta tabela para cada requisito escolhido.

| Decisão | Requisito 1 | Requisito 2 |
| --- | --- | --- |
| Nome do requisito |  |  |
| Classificação ISO/IEC 25010 |  |  |
| Problema atual no sistema |  |  |
| O que vamos medir? |  |  |
| Unidade da medição |  |  |
| Como vamos medir? |  |  |
| Valor da baseline |  |  |
| Valor-alvo |  |  |
| Mínimo aceitável |  |  |
| Refactoring proposto |  |  |
| Testes de regressão |  |  |
| Riscos/efeitos secundários |  |  |

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
