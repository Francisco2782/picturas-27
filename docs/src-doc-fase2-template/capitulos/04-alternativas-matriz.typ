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
    [ALT-1], [Consumidores concorrentes], [Réplicas do worker na mesma fila.], [Mantém], [Documento de apoio, secção 7.],
    [ALT-2], [Ferramentas de vídeo distribuídas], [Um serviço por efeito, com encadeamento.], [Altera o padrão de vídeo], [Documento de apoio, secções 3 e 6.],
    [ALT-3 (opcional)], [Filas por tipo de carga], [Separar trabalhos leves e pesados.], [Altera a topologia de despacho], [Documento de apoio, secções 4 e 7.],
  ),
)

== Análise de cada alternativa

#orientacao[
  Copiem o bloco abaixo para cada alternativa. Para cada uma, descrevam a coerência com o padrão global, o efeito nos
  atributos de qualidade, as vantagens, as desvantagens ou riscos, e o custo e risco de migração. Evitem listas
  genéricas: cada ponto deve referir algo concreto da solução do PictuRAS (e citar evidência `EV-nn` ou hipótese `H-nn`).
]

*ALT-1 — Consumidores concorrentes*

#tabela-campos(
  [Coerência com o padrão global], [Usa a mesma fila e contrato.],
  [Efeito nos atributos de qualidade], [Permite processar B durante A.],
  [Vantagens potenciais], [Mantém o pipeline local.],
  [Desvantagens ou riscos], [Mais memória e fechos concorrentes.],
  [Custo e risco de migração (a funcionalidade existente tem de ser preservada)], [Mudança de escala e correção de concorrência.],
)

*ALT-2 — Ferramentas de vídeo distribuídas*

#tabela-campos(
  [Coerência com o padrão global], [Aproxima-se da distribuição por efeito das imagens.],
  [Efeito nos atributos de qualidade], [Permite escalar cada etapa independentemente.],
  [Vantagens potenciais], [Isola efeitos e falhas por serviço.],
  [Desvantagens ou riscos], [Acrescenta transferências e pode repetir codificação.],
  [Custo e risco de migração], [Exige integração de novos serviços e validação do pipeline.],
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

#tab([Matriz de comparação de padrões],
  tabela(
    colunas: (5.6cm, 4.2cm, 4cm, 4cm, 4cm),
    tamanho: 8.5pt,
    [Atributo de qualidade (ISO/IEC 25010)], [Padrão global atual (referência)], [Padrão atual do vídeo], [ALT-1], [ALT-2],
    [Relação com o padrão global], [—], [Pipeline local com despacho assíncrono.], [Mantém a fila e o pipeline.], [Distribui os efeitos de vídeo.],
    [Eficiência de desempenho: comportamento temporal], [Assíncrono por ferramenta.], [Trabalhos aguardam o único consumidor.], [Amostra final de B arrancou durante A.], [Pode aumentar I/O e recodificação.],
    [Eficiência de desempenho: capacidade / elasticidade], [Escala por ferramenta.], [Um vídeo de cada vez na base.], [Duas réplicas validadas.], [Escala por etapa.],
    [Fiabilidade: tolerância a falhas / recuperabilidade], [Ack automático nas ferramentas de imagem.], [Ack manual no worker de vídeo.], [Ack manual e fecho concorrente protegido.], [Isolamento por etapa com mais pontos de falha.],
    [Manutenibilidade: modularidade / modificabilidade], [Ferramentas especializadas.], [Efeitos no mesmo serviço.], [Mesma estrutura interna.], [Maior independência por efeito e mais coordenação.],
    [Segurança], [Gateway no perímetro; validação TLS interna desativada (`EV-01`).], [Percurso existente.], [Mesmos contratos e fronteiras.], [Mais dependências internas.],
    [Usabilidade: operabilidade], [O estado visível depende do frontend.], [Overlay na base.], [A redução da espera foi medida separadamente da interface.], [Depende de acompanhar as etapas no cliente.],
  ),
)
]

== Adequação do padrão atual

`H-03`: duas réplicas de `video_tool` na fila partilhada devem reduzir a espera média de B (`b_wait_seconds`) para 15 s ou menos. A hipótese foi testada comparando uma e duas réplicas no cenário A/B e confirmada na revisão `3cb1b74`: a espera média de B foi 0,123 s (`docs/sessoes/2026-11-24-validacao-final-3cb1b74.md`).

`H-04`: persistir o snapshot e remover o overlay deve permitir 12/12 ações e recuperar o acompanhamento após navegação, recarregamento e reconexão. A hipótese foi testada em três ensaios no Chromium e confirmada: 12/12 ações e recuperação nos 3/3 ensaios de cada percurso (`docs/sessoes/2026-11-24-validacao-final-3cb1b74.md`).

ALT-1 foi selecionada para preservar o pipeline e limitar as mudanças no despacho. ALT-2 exigiria rever a coordenação e os ficheiros intermédios. ALT-3 exigiria encaminhar trabalhos consoante a carga. As duas últimas ficaram na análise conceptual.
