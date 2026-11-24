# Reentrega de respostas de processamento

## Problema e decisão

Se `projects` for interrompido depois de gravar um resultado e antes de remover o registo `Process`, o RabbitMQ pode voltar a entregar a resposta. O registo ainda está pendente e a inserção anterior podia ser repetida. Na extração de fotogramas, a interrupção também pode acontecer depois de guardar apenas parte do manifesto.

O MongoDB identifica cada saída nova pela combinação do ID do trabalho e da sua posição na resposta. Uma resposta repetida reutiliza o resultado já gravado. Na extração, só são guardados os fotogramas em falta. Se duas cópias da resposta chegarem antes da primeira inserção, o índice único conserva um registo e apenas o upload da inserção perdedora é removido. A limpeza de resultados de uma execução falhada ou cancelada continua a usar o token da execução e protege resultados já confirmados. O índice ignora documentos antigos sem chave, pelo que esses resultados continuam legíveis sem migração.

A correção cobre a janela entre registar uma saída e remover o trabalho. Um corte entre o upload e a gravação do respetivo registo ainda pode deixar um objeto órfão, pois o armazenamento e o MongoDB são operações separadas. A janela distinta entre remover o trabalho e confirmar o lote também ficou fora desta alteração. Para evitar misturar registos criados pelo código anterior e pelo novo para a mesma mensagem, atualizar o serviço com as filas de processamento vazias.

## Verificação

| Verificação | Resultado |
| --- | --- |
| `node --test projects/tests/*.test.js frontend/tests/processing-status.test.mjs` | 38 testes passaram. O ensaio de fotogramas confirma que uma repetição só guarda os ficheiros em falta. |
| `PYTHONDONTWRITEBYTECODE=1 python3 -m pytest -p no:cacheprovider -q evaluation/tests` | 14 testes passaram. |
| `docker run --rm --network picturas-validation_elk picturas-validation-projects-redelivery:local node /app/tests/project-concurrency.integration.js` | 5 testes passaram. A falha injetada entre gravação e remoção deixou o trabalho pendente. A repetição conservou o mesmo ID, efetuou um só upload e concluiu o lote. Duas cópias concorrentes retiveram um registo e um objeto simulado. Dois resultados antigos sem chave permaneceram legíveis. |
| `PYTHONDONTWRITEBYTECODE=1 python3 evaluation/evidence/phase2-validation-2026-11-24-redelivery/check_integrated.py` | Passaram imagem, dois vídeos, lote misto, falha de trim, extração de três fotogramas e permissões. Os resultados publicados foram descarregados por HTTP 200 e os ZIP passaram a verificação de integridade. O lote falhado publicou zero resultados. |
| `git diff --check` | Passou. O Dockerfile e a versão do Typst vinda de `origin/main` foram preservados. |

Construí a imagem local de validação sobre `picturas-validation-projects-concurrency:local`, copiando os modelos, controladores, utilitários e rotas alterados. Substituí apenas `projects` na stack dedicada com `docker compose up -d --no-deps --no-build projects` e uma configuração adicional local. A primeira chamada regressou HTTP 500 enquanto o serviço arrancava. A segunda série foi iniciada com a ligação ao MongoDB estabelecida.

O `git fetch origin main` encontrou cinco commits do remoto. Guardei a campanha anterior e as melhorias de legibilidade em `444267c` e o merge `f0ecfe4` integrou a revisão do relatório e dos exercícios da equipa. Consolidei depois as linhas duplicadas de estado em `AGENTS.md`, preservando a ligação à campanha original e o comando de recontagem.

Os logs e o JSON da API estão em `evaluation/evidence/phase2-validation-2026-11-24-redelivery/`. A reprodução da interrupção usou MongoDB real e um erro injetado antes da remoção do trabalho. O armazenamento real foi exercitado na verificação separada pela API. As medições de capacidade e de Chromium continuam associadas à revisão registada na [campanha anterior](2026-11-24-validacao-entrega.md).
