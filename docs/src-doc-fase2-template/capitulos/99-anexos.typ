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

== Requisitos prévios do ambiente

Para lançar e avaliar a plataforma PictuRAS, o sistema anfitrião deve satisfazer os seguintes requisitos:
- Sistema Operativo Linux (Ubuntu/Debian x86_64 recomendado) ou macOS;
- Docker Engine versão $>= 24.0$ e Docker Compose v2 ou superior;
- Pelo menos 16 GB de memória RAM disponíveis e 20 GB de espaço em disco;
- Node.js versão $>= 20.x$ (para execução das suites de teste do orquestrador e frontend);
- Python versão $>= 3.10$ com `ffmpeg` e `ffprobe` instalados no PATH do sistema.

== Arranque do sistema via Docker Compose

1. #strong[Limpeza de volumes legados (obrigatório na primeira execução):]
   ```bash
   docker compose down -v --remove-orphans
   ```
2. #strong[Construção e arranque dos microsserviços:]
   ```bash
   docker compose up -d --build
   ```
3. #strong[Escalar o trabalhador de vídeo para 2 réplicas (cenário de capacidade):]
   ```bash
   docker compose up -d --no-build --scale video_tool=2 video_tool
   ```
4. #strong[Acesso à interface e serviços:]
   - Interface Web (Next.js): `https://localhost:8080` (aceitar o certificado autoassinado);
   - Gestão do RabbitMQ: `http://localhost:15672` (credenciais: `user` / `password`);
   - Ponto de entrada da API Gateway: `https://localhost:8080/api-gateway/`.

== Execução dos testes automatizados de regressão

1. #strong[Testes do trabalhador de vídeo (77 testes PyTest no host):]
   ```bash
   cd Tools/video && python3 -m venv .venv
   .venv/bin/pip install -r requirements-dev.txt
   .venv/bin/python -m pytest -q tests
   ```
2. #strong[Testes do orquestrador de projetos e reconciliação do frontend (38 testes Node.js):]
   ```bash
   node --test projects/tests/*.test.js frontend/tests/processing-status.test.mjs
   ```
3. #strong[Testes do framework e scripts de avaliação (14 testes PyTest):]
   ```bash
   python3 -m pytest -q evaluation/tests
   ```

== Repetição dos ensaios experimentais e auditoria D-01

O pacote oficial de evidência `evaluation/evidence/picturas-phase2-d01.tar.gz` contém os registos brutos e manifestos auditados:
1. #strong[Verificação de integridade dos 141 ficheiros do arquivo:]
   ```bash
   tar -xzf evaluation/evidence/picturas-phase2-d01.tar.gz -C /tmp/picturas-d01-check
   cd /tmp/picturas-d01-check && sha256sum -c SHA256SUMS
   ```
2. #strong[Recontagem e sumarização das séries de capacidade:]
   ```bash
   PYTHONDONTWRITEBYTECODE=1 python3 evaluation/summarize.py \
     evaluation/evidence/official-baseline-performance-2026-11-17 --runs 3
   PYTHONDONTWRITEBYTECODE=1 python3 evaluation/summarize.py \
     evaluation/evidence/phase2-final-2026-11-22/performance-retry --runs 3
   ```
3. O guia detalhado de reprodução passo a passo com injeção de falhas e automação no Chromium encontra-se documentado em `evaluation/phase2-reproduction.md`.

= Glossário

#tabela(
  colunas: (3.8cm, 1fr),
  tamanho: 8.5pt,
  [Termo / Sigla], [Definição],
    [ADR], [Architecture Decision Record: registo padronizado que documenta uma decisão arquitetural, o seu contexto, táticas, alternativas e consequências.],
    [AMQP], [Advanced Message Queuing Protocol: protocolo de mensageria assíncrona utilizado pelo _broker_ RabbitMQ para comunicação entre serviços.],
    [Baseline], [Linha de base: estado empírico e métricas do sistema original antes de qualquer intervenção de _refactoring_, servindo de referência comparativa.],
    [Competing Consumers], [Padrão de consumidores concorrentes: múltiplas instâncias trabalhadoras ligadas à mesma fila de mensagens, distribuindo a carga de forma equilibrada.],
    [Head-of-Line Blocking], [Bloqueio de cabeça de fila: fenómeno em que um pedido longo ou bloqueante no início de uma fila impede o avanço de todos os pedidos subsequentes mais leves.],
    [Lossy Codec], [Codec com compressão com perdas (e.g. H.264 para vídeo, AAC para áudio): recodificações sucessivas degradam cumulativamente a fidelidade do sinal original.],
    [Makespan], [Duração total decorrida desde a submissão da primeira tarefa até à conclusão definitiva da última tarefa de um lote computacional.],
    [Overlay], [Camada visual de sobreposição modal na interface web que bloqueia o acesso e a interação do utilizador com os restantes elementos do ecrã.],
    [Prefetch Count], [Mecanismo do RabbitMQ que limita o número de mensagens pendentes não confirmadas entregues antecipadamente a um consumidor.],
    [Refactoring], [Reestruturação interna da arquitetura e do código-fonte com o objetivo de melhorar atributos não funcionais, sem alterar o comportamento funcional externo.],
    [Single-Pass Processing], [Processamento em passagem única: descodificação do ficheiro de vídeo uma só vez, aplicação de filtros encadeados em memória e codificação final única.],
    [Snapshot Pattern], [Padrão de persistência que guarda uma fotografia atómica e imutável do estado e progresso corrente de uma execução longa no banco de dados.],
    [Faster-Whisper], [Implementação de alto desempenho do modelo Whisper da OpenAI utilizando a biblioteca CTranslate2 com quantização int8 para transcrição fonética em CPU.],
    [EV / H], [Evidência verificável auditada no código ou configuração (`EV-nn`) / Hipótese formulada sujeita a confirmação experimental (`H-nn`).],
    [QS / CAND], [Quality Scenario (`QS-nn`): cenário de qualidade formalizado segundo a ISO/IEC 25010 / Candidato a Requisito Não Funcional (`CAND-n`).],
    [TAT / DA], [Tática arquitetural formal de desenho (`TAT-nn`) / Decisão arquitetural consolidada no relatório (`DA-n`).]
)
