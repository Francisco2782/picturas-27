#import "../template.typ": *

#paisagem[
= Trade-offs, Medição e Preservação Funcional

#orientacao[
  *Origem:* Exercício 7, secção 5 do _template_ (e os riscos de preservação funcional do Bloco 2, secção 6).

  *Objetivo do capítulo:* mostrar que as decisões foram avaliadas além do atributo que melhoram (_trade-offs_), que a
  melhoria foi medida de forma comparável (antes e depois) e que o comportamento funcional foi preservado.

  A mesma medição é feita *antes e depois* do _refactoring_, no mesmo ambiente. *Não inventem valores* de _baseline_, alvo
  ou mínimo aceitável: fixam-se após a medição inicial. Guardem os _scripts_, os dados e o ambiente das medições para os
  reutilizar como _baseline_.
]

== Matriz de efeitos

#orientacao[
  Para cada decisão, indiquem se cada atributo *melhora* (↑), *degrada* (↓) ou fica *neutro* (=), e justifiquem. Incluam
  no mínimo quatro atributos, e entre eles a característica do outro cenário: uma melhoria num atributo costuma ter um
  custo noutro, e é isso que esta matriz deve revelar. Se uma decisão degradar um atributo, digam como a equipa vai
  gerir esse custo.
]

#tab([Matriz de efeitos das decisões],
  tabela(
    colunas: (1.8cm, 2.6cm, 3.4cm, 2.4cm, 2.4cm, 3.6cm, 1fr),
    tamanho: 8.5pt,
    [Decisão], [Desempenho], [Disponibilidade / Fiabilidade], [Segurança], [Usabilidade], [Manutenibilidade / Testabilidade], [Justificação],
    [DA-1], [Menor espera de B. Mais RAM agregada.], [Dois resultados simultâneos preservados em P-02.], [Mesmas interfaces.], [B inicia mais cedo.], [Mais caminhos concorrentes a validar.], [Duas réplicas consomem a mesma fila com `prefetch_count=1`.],
    [DA-2], [Mais pedidos HTTP observados.], [Recuperação de estado em 3/3 após recarregamento e reconexão.], [Controlos de cancelamento verificados por permissão.], [12/12 ações.], [Testes de reconciliação e de estado.], [O snapshot recupera a observação da execução durante falhas de ligação do browser.],
  ),
)
]

== Interação entre DA-1 e DA-2

#tab([Interação entre as decisões],
  tabela(
    colunas: (2.2cm, 2.2cm, 4.4cm, 1fr),
    [Decisão A], [Decisão B], [Efeito (pré-requisito, sinergia ou conflito)], [Razão / evidência],
    [DA-1], [DA-2], [Sinergia e concorrência], [As duas configurações finais atingiram os alvos em ensaios próprios. O cliente valida o token da execução e preserva a precedência de estados terminais perante eventos fora de ordem.],
  ),
)

== Plano de medição

#tab([Plano de medição],
  tabela(
    colunas: (1.6cm, 3.2cm, 3cm, 2.6cm, 2.4cm, 2.8cm),
    tamanho: 8pt,
    [Cenário], [Cenário de teste e carga], [Ambiente (máquina, recursos, versões)], [O que se regista], [Repetições e agregação], [Onde ficam os _scripts_ e os dados],
    [QS-01], [A legenda 177 s. B aplica brilho a dois MP4 de 10 s e um MOV de 6 s após a resposta de A mais 1,5 s.], [i7-13650HX, 20 CPUs lógicos, Docker Engine 29.9.3, Compose 5.7.1.], [Pedidos, arranques, resultados, RabbitMQ, CPU e RAM por worker e por grupo.], [Um aquecimento e três ensaios válidos por série. Média e amplitude.], [`evaluation/run_scenario.py` e arquivo D-01.],
    [QS-02], [A legenda um excerto de 10 s. O utilizador abre B, usa a barra e regressa a A durante o processamento.], [Chrome 157.0.8103.50, 1280 × 720, sessão premium.], [Quatro ações, recuperação, conclusões prematuras, pedidos, eventos e download.], [Um aquecimento e três ensaios válidos. Contagem de ações e recuperações.], [`browser_u04.py` e registos no arquivo D-01.],
  ),
)

== Resultados das medições

#orientacao[
  Para cada requisito não funcional, apresentem os valores medidos *antes* (_baseline_) e *depois* do _refactoring_, com o
  mesmo método e nas mesmas condições (plano acima), e comparem-nos com o valor-alvo e o valor mínimo aceitável fixados no
  capítulo 6. Os dados brutos e os _scripts_ ficam no repositório entregue.

  Na análise, sejam críticos: o que melhorou, o que não foi atingido e porquê, que outros atributos foram afetados
  (confirmando ou não a matriz de efeitos) e que ameaças à validade das medições existem.
]

#tab([Resultados das medições],
  tabela(
    colunas: (1.6cm, 1fr, 2cm, 2cm, 2cm, 2cm, 2cm),
    tamanho: 8.5pt,
    [Cenário], [Medição (o que se mede, unidade)], [Antes (_baseline_)], [Depois], [Valor-alvo], [Mínimo aceitável], [Atingido?],
    [QS-01], [Espera média até ao primeiro arranque de B (s)], [61,727], [0,113], [≤ 15 s], [≤ 30 s], [Alvo],
    [QS-02], [Ações A/B e recuperação durante A], [6/12, navegação e recarregamento 0/3], [12/12, 3/3 por recuperação, 0 falsas conclusões], [12/12, navegação e recarregamento 3/3], [≥ 3/4 por ensaio, navegação e recarregamento 3/3, 0 falsas conclusões], [Alvo],
  ),
)

*Análise dos resultados* (por requisito não funcional):

Na série oficial com uma réplica, o único consumidor executava a legendagem longa enquanto B aguardava. Na série final, o primeiro vídeo de B arrancou na segunda réplica antes de A terminar nos três ensaios. O intervalo medido começa imediatamente antes do pedido de B e acaba no primeiro arranque registado pelo worker. Inclui despacho e chegada ao worker. Os três ficheiros de capacidade têm os mesmos SHA-256 nos manifestos. A revisão da aplicação, as imagens e o limite de volumes do SeaweedFS mudaram entre as campanhas. A repetição com uma réplica e o instrumento final também registou espera pelo consumidor ocupado, com média de 82,242 s. Essa repetição usou imagens reconstruídas e acesso direto por HTTP em loopback.

#block(breakable: false, tab([Capacidade por campanha. Média e amplitude nas duas séries com o instrumento final],
  tabela(
    colunas: (1fr, 2.3cm, 3.3cm, 3.3cm),
    tamanho: 8.5pt,
    [Métrica], [Base oficial], [Base repetida], [Final],
    [Duração de A (s)], [63,888], [85,048 (82,332–86,418)], [80,961 (78,326–84,255)],
    [Duração de B (s)], [68,374], [90,196 (86,803–92,902)], [9,676 (8,285–10,394)],
    [Espera de B (s)], [61,727], [82,242 (79,325–84,393)], [0,113 (0,093–0,132)],
    [Duração do lote (s)], [69,925], [91,755 (88,370–94,460)], [80,961 (78,326–84,255)],
    [Fila pronta, máximo], [3], [3 (3–3)], [2 (2–2)],
    [Mensagens por confirmar, máximo], [1], [1 (1–1)], [2 (2–2)],
    [Pico de CPU do grupo (%)], [830,810], [756,550 (673,600–803,450)], [738,700 (660,900–821,880)],
    [Pico de RAM do grupo (GB)], [3,051], [2,860 (2,848–2,869)], [4,289 (4,014–4,442)],
  ),
))

A média do pico de RAM subiu de 2,86 para 4,29 GB face à base repetida. As amplitudes dos picos de CPU sobrepõem-se. O instrumento inicial esperava pela conclusão de A para observar B. O instrumento final consulta ambos em cada ronda. As durações iniciais ficam como referência histórica, e as diferenças de imagens e de acesso limitam a atribuição das diferenças de duração ao número de réplicas.

Em operabilidade, A manteve o estado visível nas quatro ações em cada ensaio final. A navegação, o recarregamento e a reconexão tiveram 3/3 recuperações cada, com zero conclusões prematuras e três downloads HTTP 200. A base registou 6/12 ações e 0/3 recuperações por navegação e por recarregamento. A duração média das legendas passou de 6,029 para 6,153 s. Foram observados 28 e 40 pedidos de API por ensaio na base e no final, incluindo 6 e 8 pedidos de estado. Os totais incluem navegação, hidratação e a reconexão explícita do teste final. A base registou zero eventos de progresso reconhecíveis, pelo que a comparação de duplicados e ordem carece de observações equivalentes.

Num ensaio complementar com quatro pares e o mesmo vídeo de 10 s, uma consulta de estado por segundo acrescentou quatro pedidos e 1 048 bytes de corpo HTTP em quatro segundos. A mediana por pedido foi 7,75 ms. Os tempos de conclusão variaram em ambos os sentidos entre pares. O ensaio quantifica o custo HTTP de um observador. O custo em CPU e memória fica por medir.

#pagebreak(weak: true)
== Preservação funcional

R-01 a R-04 passaram com 38 testes Node, 76 testes do worker, 14 testes do instrumento e o build de produção do frontend.

QS-03 foi uma verificação complementar de regressão da DA-1 (QS-01). Ao validar dois consumidores na mesma fila, verificámos se o processamento em lote preservava a reentrega, o resultado e a limpeza de ficheiros após uma interrupção. As primeiras provas revelaram ficheiros parciais após interromper um worker e perda do trabalho em curso após reiniciar o RabbitMQ. Depois das correções, as quatro provas recuperaram o mesmo trabalho, publicaram um MP4 descarregável e deixaram zero novos ficheiros parciais. Os requisitos selecionados mantêm-se QS-01 e QS-02. A suite do worker passou a 77 testes e a regressão de extração publicou quatro PNGs descarregáveis a partir de dois vídeos.

F8 corrigiu uma falha herdada de reembolso da quota de vídeo ao cancelar. Foi verificada em separado com contas gratuitas, incluindo cancelamentos concorrentes, uma repetição após indisponibilidade temporária e um projeto partilhado. As campanhas dos dois requisitos usaram contas premium.

#tab([Preservação funcional e testes de regressão],
  tabela(
    colunas: (2.4cm, 3.8cm, 2.8cm, 3.2cm, 1fr),
    tamanho: 8.5pt,
    [Zona alterada], [Testes de regressão existentes (`Tools/video/tests`, `projects/tests`, …)], [Lacunas de teste], [Testes acrescentados], [Resultado (imagem e vídeo)],
    [DA-1, orquestração], [`projects/tests`, `Tools/video/tests`], [Conclusões simultâneas e perda de resultados.], [Barreira controlada e prova com MongoDB e armazenamento reais (P-02).], [Dois resultados distintos e descarregáveis.],
    [DA-2, estado e frontend], [Testes do orquestrador e do estado no frontend.], [Tokens antigos, ordem, permissões e cancelamento durante navegação.], [Regressão A/B e F5 em Chromium.], [Primeira visita a estados terminais, permissões e respostas 204 e 409 verificadas.],
  ),
)

#tab([Riscos para a preservação funcional e mitigação],
  tabela(
    colunas: (3.4cm, 3.2cm, 4cm, 3.2cm),
    tamanho: 8.5pt,
    [Risco], [Funcionalidade afetada (imagem / vídeo)], [Mitigação], [Teste de regressão],
    [Perder resultados num fecho concorrente], [Vídeo e lotes mistos], [Atualização condicional e verificação do lote.], [P-02 e regressão com MongoDB e armazenamento.],
    [Publicar resultados parciais após falha], [Imagem e vídeo], [Publicação condicionada ao estado do lote.], [Imagem só, vídeo só e lote misto com ZIP íntegro. Falha em lote misto com zero resultados publicados.],
  ),
)
