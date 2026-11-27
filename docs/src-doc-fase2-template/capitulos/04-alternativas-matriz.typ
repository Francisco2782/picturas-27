#import "../template.typ": *

= Alternativas e Matriz de Comparação

#orientacao[
  *Origem:* Exercício 6, Bloco 1, secção 3 do _template_.

  *Objetivo do capítulo:* comparar o padrão atual com alternativas relevantes *para o processamento de vídeo*, de forma
  fundamentada, e concluir se o padrão atual é adequado. Entre duas e três alternativas. O padrão global é o contexto da
  comparação: indiquem sempre se cada alternativa o *mantém* ou o *altera*.

  *Restrição da fase:* é de _refactoring_. As alternativas têm de preservar o comportamento funcional; por isso, o
  custo e o risco de migração têm de ser analisados para cada uma. Consultem os slides da aula 11 e o documento de apoio
  de padrões arquiteturais; se for relevante, incluam uma alternativa ao próprio padrão global como termo de comparação.
]

== Alternativas consideradas

#tab([Alternativas consideradas],
  tabela(
    colunas: (1.6cm, 3.4cm, 1fr, 3cm, 2.4cm),
    tamanho: 8.5pt,
    [ID], [Nome / padrão], [Descrição breve], [Mantém ou altera o padrão global?], [Fonte],
    [ALT-1], [Consumidores concorrentes], [Réplicas homogéneas do `video_tool` a consumir em paralelo a mesma fila `video_queue` (`prefetch_count=1`).], [Mantém], [Documento de apoio de padrões arquiteturais, secção 7.],
    [ALT-2], [Ferramentas de vídeo distribuídas], [Decomposição do _pipeline_ de vídeo num serviço por efeito (_pipe-and-filter_ distribuído), espelhando o caminho de imagens.], [Mantém o global; altera o padrão do vídeo], [Documento de apoio de padrões arquiteturais, secções 3 e 6.],
    [ALT-3], [Filas por tipo de carga], [Encaminhamento separado para filas dedicadas consoante o peso computacional (ex.: legendagem vs. filtros leves).], [Altera a topologia de despacho], [Documento de apoio de padrões arquiteturais, secções 4 e 7.],
  ),
)

== Análise de cada alternativa

#orientacao[
  Copiem o bloco abaixo para cada alternativa. Para cada uma, descrevam a coerência com o padrão global, o efeito nos
  atributos de qualidade, as vantagens, as desvantagens ou riscos, e o custo e risco de migração. Evitem listas
  genéricas: cada ponto deve referir algo concreto da solução do PictuRAS (e citar evidência `EV-nn` ou hipótese `H-nn`).
]

*ALT-1 - Consumidores concorrentes*

#tabela-campos(
  [Coerência com o padrão global], [Total: preserva a fila `video_queue`, o contrato de mensagens e a fronteira entre orquestrador e trabalhador (`EV-03`, `EV-04`).],
  [Efeito nos atributos de qualidade], [Melhora a capacidade e reduz o tempo bloqueado em espera (permite processar B enquanto A legenda, `H-03`), com aumento de consumo agregado de RAM.],
  [Vantagens potenciais], [Preserva a passagem única de descodificação/codificação (`Tools/video/effects.py`, `EV-04`) e exige alterações mínimas no despacho.],
  [Desvantagens ou riscos], [Maior pico de memória por réplica ativa e risco de condição de corrida no fecho concorrente de lotes em `projects` (`H-01`).],
  [Custo e risco de migração (a funcionalidade existente tem de ser preservada)], [Baixo a médio: ajuste de escala no Compose (`EV-08`) e proteção atómica do fecho do lote no orquestrador, validada em regressão (`H-01`).],
)

*ALT-2 - Ferramentas de vídeo distribuídas*

#tabela-campos(
  [Coerência com o padrão global], [Alinha o vídeo com o estilo _pipe-and-filter_ distribuído já usado nas imagens (`EV-03`).],
  [Efeito nos atributos de qualidade], [Melhora a modularidade e a elasticidade por efeito, mas degrada o comportamento temporal e a utilização de recursos devido a múltiplas recodificações e I/O em disco (`EV-04`).],
  [Vantagens potenciais], [Isola falhas e dependências (ex.: Faster-Whisper em `EV-05` separado dos filtros `ffmpeg`) e permite escalar apenas etapas pesadas.],
  [Desvantagens ou riscos], [Perde a partilha de passagem em `Tools/video/effects.py`, multiplica transferências no volume `image_data` (`H-02`) e aumenta pontos de falha intermédios.],
  [Custo e risco de migração], [Elevado: exige criar novos serviços, filas em `rabbitMQ/definitions.json`, alterar o despacho em `projects` e revalidar todo o _pipeline_ dentro do âmbito restrito de _refactoring_.],
)

*ALT-3 - Filas por tipo de carga*

#tabela-campos(
  [Coerência com o padrão global], [Mantém os microsserviços assíncronos, mas altera a topologia de despacho e as declarações do _broker_ (`rabbitMQ/definitions.json`).],
  [Efeito nos atributos de qualidade], [Evita que tarefas pesadas (`subtitles`, `EV-05`) bloqueiem filtros rápidos em `video_queue`, melhorando o isolamento de latência.],
  [Vantagens potenciais], [Permite reservar capacidade dedicada para operações leves sem replicar modelos pesados em todos os trabalhadores.],
  [Desvantagens ou riscos], [Acopla o orquestrador `projects` à classificação heurística do custo de cada efeito e subutiliza trabalhadores dedicados quando um dos perfis não tem carga.],
  [Custo e risco de migração], [Médio a alto: exige regras de encaminhamento no orquestrador, novas filas/bindings e manutenção de perfis distintos de trabalhadores.],
)

#paisagem[
== Matriz de comparação de padrões

#orientacao[
  Atribuam um nível a cada atributo para o padrão global (referência), para o padrão atual do vídeo e para cada
  alternativa. A escala é à vossa escolha (e.g., Alto / Médio / Baixo) e deve ser a mesma em toda a matriz.

  *Justifiquem cada célula* com evidência da solução (`EV-nn` ou `H-nn`) numa frase curta, logo na própria célula: as
  avaliações sem fundamento não são valorizadas. A matriz inclui o padrão global como referência para se ver o que
  cada alternativa ganha ou perde em relação a ele. Os atributos e subcaracterísticas seguem a ISO/IEC 25010; podem
  acrescentar linhas para outros atributos relevantes.
]

A matriz usa a escala *Alto / Médio / Baixo*, atribuída por comparação direta
entre as colunas para o mesmo atributo: *Alto* significa que o padrão
satisfaz bem o atributo no contexto do PictuRAS; *Médio*, que o satisfaz com
limitações conhecidas; *Baixo*, que o compromete de forma relevante. As
colunas ALT-2 e ALT-3 são *projeções conceptuais*: não foram implementadas
nem medidas nesta fase, pelo que os seus níveis resultam da análise estática
e da experiência com a baseline. Pelo contrário, os valores do padrão atual
do vídeo e da ALT-1 assentam em medições (`H-03`, `H-04`). Cada célula é
justificada com evidência (`EV-nn`) ou hipótese (`H-nn`).

#tab([Matriz de comparação de padrões],
  tabela(
    colunas: (4.7cm, 3.8cm, 3.8cm, 3.8cm, 3.8cm, 3.8cm),
    tamanho: 7.5pt,
    [Atributo de qualidade (ISO/IEC 25010)], [Padrão global atual (referência)], [Padrão atual do vídeo], [ALT-1 (Consumidores concorrentes)], [ALT-2 (Ferramentas distribuídas)], [ALT-3 (Filas por tipo de carga)],
    [Relação com o padrão global], [Referência: microsserviços assíncronos por fila (`EV-03`).], [Mantém a comunicação assíncrona, mas concentra o _pipeline_ num serviço (afasta-se na decomposição, `EV-04`).], [Mantém integralmente a fila e o contrato (`EV-03`, `EV-04`).], [Altera o padrão do vídeo para _pipe-and-filter_ distribuído.], [Mantém o global assíncrono, mas altera o encaminhamento e o contrato de despacho (`EV-03`).],
    [Eficiência de desempenho: comportamento temporal], [Médio - assíncrono por ferramenta, com encadeamento passo a passo (`EV-03`).], [Baixo - `prefetch_count=1` num único worker bloqueia B durante `subtitles` (`EV-04`, `EV-05`).], [Alto - duas réplicas permitem arrancar B durante A (`H-03`).], [Baixo - recodificações repetidas e mais I/O intermédio (`EV-04`, `H-02`).], [Médio - tarefas rápidas deixam de esperar pela legendagem quando há consumidor dedicado livre, mas o ganho depende da distribuição da carga (`EV-05`).],
    [Eficiência de desempenho: capacidade], [Alto - escala independente por ferramenta de imagem (`EV-03`).], [Baixo - limitado a uma réplica por omissão (`EV-08`).], [Alto - duas réplicas validadas sob carga concorrente (`H-03`).], [Alto - escala granular por etapa, com maior sobrecarga de rede/disco.], [Médio - escala por fila, com risco de capacidade ociosa nos perfis sem carga (`EV-08`).],
    [Fiabilidade: tolerância a falhas / recuperabilidade], [Baixo - ferramentas de imagem usam `auto_ack=True` (`EV-09`).], [Médio - ack manual protege a tarefa, sem validação de fecho concorrente (`EV-04`, `H-01`).], [Alto - ack manual mantido e fecho concorrente protegido (`EV-04`, `H-01`).], [Médio - isola falhas por efeito, mas multiplica pontos de falha intermédios.], [Médio - preserva o _ack_ manual, mas acrescenta encaminhamento e caminhos de falha novos a validar (`EV-04`).],
    [Manutenibilidade: modularidade / modificabilidade], [Alto - ferramentas especializadas e desacopladas (`EV-03`).], [Médio - efeitos acoplados no mesmo serviço, partilhando passagem (`EV-04`).], [Médio - preserva a estrutura interna sem novas dependências.], [Alto - cada efeito evolui isoladamente, com maior custo de coordenação.], [Médio - reutiliza o _worker_ e acrescenta regras de classificação de custo no orquestrador (`EV-03`).],
    [Segurança], [Baixo - gateway no perímetro, mas TLS interno desativado (`EV-01`).], [Baixo - herda o perímetro e as ligações internas existentes (`EV-01`).], [Baixo - mantém contratos e fronteiras existentes (`EV-01`).], [Baixo - mais ligações internas sob o mesmo perímetro (`EV-01`).], [Baixo - novas filas sob o mesmo perímetro, com o TLS interno desativado (`EV-01`).],
    [Usabilidade: operabilidade], [Baixo - visibilidade depende de estado local no browser (`EV-10`).], [Baixo - _overlay_ bloqueante e estado volátil na baseline (`EV-10`).], [Médio - reduz a espera de B, mas requer DA-2 na interface (`H-03`, `H-04`).], [Baixo - acompanhamento fragmentado por múltiplas etapas no cliente.], [Médio - reduz a espera das tarefas rápidas; a recuperação da UI continua dependente do _frontend_ (`EV-10`, `H-04`).],
  ),
)
]

== Adequação do padrão atual

O padrão global assíncrono é adequado para desacoplar o cliente do processamento em lote, e o encapsulamento do _pipeline_ em `video_tool` evita o custo proibitivo de recodificações sucessivas. Contudo, a configuração de base com um único consumidor revela-se inadequada sob carga mista, transformando tarefas pesadas (`EV-05`) em bloqueios de cabeça de fila.

`H-03`: duas réplicas de `video_tool` na fila partilhada devem reduzir a espera média de B (`b_wait_seconds`) para 15 s ou menos. A hipótese foi testada comparando uma e duas réplicas no cenário A/B e confirmada na revisão `3cb1b74`: a espera média de B foi 0,123 s (`docs/sessoes/2026-11-24-validacao-final-3cb1b74.md`).

`H-04`: persistir o snapshot e remover o overlay deve permitir 12/12 ações e recuperar o acompanhamento após navegação, recarregamento e reconexão. A hipótese foi testada em três ensaios no Chromium e confirmada: 12/12 ações e recuperação nos 3/3 ensaios de cada percurso (`docs/sessoes/2026-11-24-validacao-final-3cb1b74.md`).

Com base nesta análise, *ALT-1* foi selecionada por responder diretamente ao risco de capacidade com menor esforço e menor risco de regressão funcional, preservando o _pipeline_ local. *ALT-2* e *ALT-3* permaneceram na análise conceptual por exigirem alterações estruturais profundas no despacho e nos artefactos intermédios.
