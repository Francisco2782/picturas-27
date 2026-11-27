# Primeira ronda de correções ao relatório da Fase 2

A ronda trata correções verificáveis sem reformular os diagramas, o plano de
medição ou o anexo. A capa de `doc-sol-arquitetural.pdf`, extraída com
`pdftotext -f 1 -l 1`, identifica a Fase 2 de 2025/2026 e janeiro de 2026.
A introdução e as fontes consultadas passaram a indicar essa identificação e
a distinguir a referência anterior do código da baseline `0523102`.

A tabela de evidência exploratória passou a apontar para os registos P-01 e
para `comparison-baseline` na recontagem da série de uma réplica. O capítulo 11
liga o contrato de acompanhamento e os testes de lotes mistos à Fase 3. O
capítulo 12 distingue a compilação verificada em 27/11 da revisão humana da
utilização de IA, ainda por registar.

`python3 evaluation/summarize.py evaluation/evidence/phase2-final-2026-11-22/comparison-baseline --runs 3`
confirmou três ensaios válidos, média de 82,242 s e intervalo de 79,325 a
84,393 s. O registo P-01 contém dois consumidores com confirmação manual e
prefetch 1. O comando `docker compose exec -T rabbitmq rabbitmqctl -q list_consumers
queue_name ack_required prefetch_count` funcionou na stack corrente com o
consumidor padrão.

O Tinymist compilou um PDF de 41 páginas. `pdftotext -layout` confirmou as
correções e `pdftoppm` renderizou as páginas 8, 11, 26, 37, 38 e 39 para
conferência visual. `git diff --check` passou. A próxima ronda fica centrada
nos diagramas de arquitetura e no anexo de reprodução.
