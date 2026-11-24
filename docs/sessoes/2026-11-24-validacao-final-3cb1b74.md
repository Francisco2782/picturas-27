# Validação final da revisão 3cb1b74

## Configuração e execução

- Revisão integral `3cb1b7492b7688a87a076af6b0f6db576835a94d`. A árvore local e a referência local de `origin/main` estavam alinhadas e limpas no início. A última correção reaproveita saídas já gravadas quando recebe a mesma resposta de processamento.
- Stack dedicada `picturas-validation` com MongoDB, RabbitMQ e SeaweedFS reais. A API entrou pelo nginx em `127.0.0.1:8080`. O RabbitMQ mostrou a fila de vídeo vazia antes do ensaio, dois consumidores e `prefetch=1` em ambos. O avaliador acedeu à gestão através do endereço interno do contentor. A SeaweedFS tinha o limite de 16 volumes da campanha anterior.
- Os SHA-256 de 29 verificações de ficheiros em execução coincidiram com o checkout. O manifesto local inclui o SHA do código, versões do host, limites dos contentores, imagens por ID e hashes das amostras e dos instrumentos.
- Corri em sequência o driver `browser_u04.py warmup trial-1 trial-2 trial-3` com Chrome 157.0.8103.50 e Playwright 1.65.2. A seguir executei o avaliador de capacidade com `--runs 3 --warmup 1 --expected-workers 2 --process-timeout 240` e os restantes parâmetros do protocolo habitual. Usei uma conta premium de teste para cada cenário e uma pasta de evidência nova.
- Evidência em `evaluation/evidence/phase2-final-3cb1b74/`. Os registos da [campanha anterior](2026-11-24-validacao-entrega.md) e da [reentrega](2026-11-24-reentrega-resultados.md) conservam as revisões e os seus testes próprios.

## QS-02 · Operabilidade

| Ensaio | Ações | Navegação | Recarregamento | Reconexão | Conclusões prematuras | Duração (s) | Pedidos API / estado | Frames WS / progresso | Percentagens repetidas / descidas |
| --- | ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Aquecimento | 4/4 | OK | OK | OK | 0 | 8,537 | 41 / 10 | 87 / 79 | 28 / 2 |
| 1 | 4/4 | OK | OK | OK | 0 | 7,065 | 40 / 9 | 85 / 77 | 27 / 0 |
| 2 | 4/4 | OK | OK | OK | 0 | 7,229 | 41 / 9 | 90 / 82 | 34 / 1 |
| 3 | 4/4 | OK | OK | OK | 0 | 7,436 | 41 / 9 | 79 / 71 | 24 / 0 |
| Ensaios medidos | **12/12** | **3/3** | **3/3** | **3/3** | **0** | **7,243 média** | **122 / 27** | **254 / 230** | **85 / 1** |

O navegador completou as ações com A ainda ativo e recuperou o estado sem conclusão prematura. Todos os quatro downloads devolveram HTTP 200 e o mesmo SHA-256 do resultado legendado de referência. `ffprobe` confirmou H.264 e AAC no primeiro ensaio medido. As descidas contam frames observados. Nos pontos pontuados, a interface concordou com a API, um snapshot recente ou um evento aplicável. Os pedidos incluem as navegações e a reconexão.

## QS-01 · Capacidade

| Ensaio | A (s) | B (s) | Espera B (s) | Lote (s) | Prontas máx. | Por confirmar máx. | CPU grupo (%) | RAM grupo (bytes) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Aquecimento · `c6418d1f24b24abd8ee826bf51f8b149` | 86,390 | 10,358 | 0,116 | 86,390 | 2 | 2 | 715,590 | 4 233 764 011 |
| 1 · `3b4e1ef344ea4e1789d73ddb2e1c69f2` | 86,369 | 10,335 | 0,113 | 86,369 | 2 | 2 | 755,460 | 4 232 690 269 |
| 2 · `e074ad28631c4953ac60a4752e02fc6f` | 92,456 | 10,364 | 0,137 | 92,456 | 2 | 2 | 761,180 | 4 257 386 331 |
| 3 · `bdacca545da34558b01be56c5ee583d6` | 90,422 | 10,340 | 0,120 | 90,422 | 2 | 2 | 746,190 | 4 265 976 266 |
| Média dos ensaios medidos | **89,749** | **10,347** | **0,123** | **89,749** | **2** | **2** | **754,277** | **4 252 017 622** |

Passaram os quatro ensaios. A espera de B foi **0,123429 s** em média, entre **0,112955 e 0,137493 s**. O alvo era 15 s e o mínimo aceitável 30 s. A baseline oficial de uma réplica tinha 61,727 s de espera média. B terminou primeiro nos três ensaios medidos. O avaliador confirmou um resultado de vídeo para A e três resultados de vídeo distintos para B e manteve as amostras individuais dos dois workers. Não se observaram reinícios, OOM ou mudanças no conjunto de réplicas. O pico de memória médio de cerca de 4,25 GB compara com 2,86 GB na série de uma réplica com o mesmo instrumento. A comparação de durações e consumo entre campanhas está sujeita às variações do ambiente registadas no manifesto.

## Pacote e reprodução

- `verify_final.py --write-tables` recalculou as oito métricas de capacidade a partir dos timestamps e amostras, conferiu os totais com as métricas de cada réplica e recontou as ações, recuperações e downloads de Chromium. O aquecimento ficou no CSV para rastreabilidade e fora dos agregados medidos.
- O pacote `evaluation/evidence/picturas-phase2-final-3cb1b74.tar.gz` contém os dados brutos, dois CSV, os instrumentos, o manifesto, os registos da última correção e o D-01 original. A verificação usa uma extração limpa, `sha256sum -c SHA256SUMS`, `python3 verify_final.py`, `python3 instruments/summarize.py capacity --runs 3` e a verificação SHA-256 e recontagem do D-01 extraído.
- A extração limpa confirmou os hashes de 45 ficheiros do pacote e de 141 ficheiros dentro do D-01. A regeneração dos dois CSV produziu ficheiros idênticos aos arquivados. A recontagem reproduziu os resultados da revisão final e da baseline oficial.
- O código da aplicação e a fonte do relatório ficaram intactos. Os resultados identificam a revisão efetivamente executada. O arquivo e os dados brutos são locais e ignorados pelo Git.
