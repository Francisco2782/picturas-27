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
    colunas: (1.6cm, 2.8cm, 3.2cm, 2.3cm, 2.4cm, 3.2cm, 1fr),
    tamanho: 8.5pt,
    [Decisão], [Desempenho], [Disponibilidade / Fiabilidade], [Segurança], [Usabilidade], [Manutenibilidade / Testabilidade], [Justificação],
    [DA-1], [↑ Capacidade e menor espera de B.\ ↓ Maior pico de RAM (+1,39 GB).], [↑ Fecho concorrente protegido e limpeza em falha.], [\= Mesmas fronteiras e contratos.], [\= A decisão preserva a interação da interface.], [↓ Mais caminhos concorrentes a testar.], [Duas réplicas em `video_queue` com `prefetch_count=1` reduzem a espera de B. Manter uma réplica por omissão limita o custo de RAM. A regressão P-02 verifica o fecho concorrente.],
    [DA-2], [↓ Mais pedidos HTTP e escritas de estado.], [↑ Recuperação 3/3 após recarregamento e reconexão.], [\= Permissões de cancelamento preservadas.], [↑ 12/12 ações sem _overlay_ bloqueante.], [↓ Requer testes de reconciliação e precedência.], [O _snapshot_ em MongoDB e a rota de estado permitem recuperar o acompanhamento. Os eventos tipados e a consulta a pedido limitam o tráfego. No ensaio de polling, a mediana por consulta foi 7,75 ms.],
  ),
)
]

== Interação entre DA-1 e DA-2

#tab([Interação entre as decisões],
  tabela(
    colunas: (2.2cm, 2.2cm, 4.4cm, 1fr),
    [Decisão A], [Decisão B], [Efeito (pré-requisito, sinergia ou conflito)], [Razão / evidência],
    [DA-1], [DA-2], [Sinergia (com exigência de ordenação)], [As duas decisões atuam em planos complementares (fila de _workers_ vs. persistência e interface). Com múltiplos _workers_ ativos em simultâneo, o cliente valida o token da execução e preserva a precedência de estados terminais perante eventos fora de ordem.],
  ),
)

== Plano de medição

#tab([Plano de medição],
  tabela(
    colunas: (1.6cm, 3.2cm, 3cm, 2.6cm, 2.4cm, 2.8cm),
    tamanho: 8pt,
    [Cenário], [Cenário de teste e carga], [Ambiente (máquina, recursos, versões)], [O que se regista], [Repetições e agregação], [Onde ficam os _scripts_ e os dados],
    [QS-01], [A legenda 177 s. B aplica brilho a dois MP4 de 10 s e um MOV de 6 s após a resposta de A mais 1,5 s.], [i7-13650HX, 20 CPUs lógicos, Docker Engine 29.9.3, Compose 5.7.1.], [Pedidos, arranques, resultados, RabbitMQ, CPU e RAM por worker e por grupo.], [Um aquecimento e três ensaios válidos por série. Média e amplitude.], [`evaluation/run_scenario.py`. Base em D-01 e série final em `phase2-final-3cb1b74` (Anexo A).],
    [QS-02], [A legenda um excerto de 10 s. O utilizador abre B, usa a barra e regressa a A durante o processamento.], [Chrome 157.0.8103.50, 1280 × 720, sessão premium.], [Quatro ações, recuperação, conclusões prematuras, pedidos, eventos e download.], [Um aquecimento e três ensaios válidos. Contagem de ações e recuperações.], [Protocolo da base em D-01. `browser_u04.py` e registos finais em `phase2-final-3cb1b74` (Anexo A).],
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
    [Cenário], [Medição (o que se mede, unidade)], [Antes (_baseline_)], [Depois (`3cb1b74`)], [Valor-alvo], [Mínimo aceitável], [Atingido?],
    [QS-01], [Espera média até ao primeiro arranque de B (s)], [61,727], [0,123], [≤ 15 s], [≤ 30 s], [Alvo],
    [QS-02], [Ações A/B e recuperação durante A], [6/12, navegação e recarregamento 0/3], [12/12, 3/3 por recuperação, 0 falsas conclusões], [12/12, navegação e recarregamento 3/3], [≥ 3/4 por ensaio, navegação e recarregamento 3/3, 0 falsas conclusões], [Alvo],
  ),
)

*Análise dos resultados* (por requisito não funcional):

Em *capacidade* (`QS-01`), na série oficial com uma réplica, o único consumidor executava a legendagem longa enquanto B aguardava na fila. Na série final (`3cb1b74`), o primeiro vídeo de B arrancou na segunda réplica antes de A terminar nos três ensaios válidos. Em cada série, a espera começa imediatamente antes do pedido HTTP de B e termina no primeiro arranque registado pelo trabalhador. Os três ficheiros de entrada têm os mesmos SHA-256 nos manifestos. A repetição com uma réplica, usando o instrumento final, confirmou a espera pelo consumidor ocupado e registou uma média de 82,242 s.

#block(breakable: false, tab([Capacidade por campanha. Média e amplitude nas duas séries com o instrumento final],
  tabela(
    colunas: (1fr, 2.3cm, 3.3cm, 3.3cm),
    tamanho: 8.5pt,
    [Métrica], [Base oficial], [Base repetida], [Final (`3cb1b74`)],
    [Duração de A (s)], [63,888], [85,048 (82,332–86,418)], [89,749 (86,369–92,456)],
    [Duração de B (s)], [68,374], [90,196 (86,803–92,902)], [10,347 (10,335–10,364)],
    [Espera de B (s)], [61,727], [82,242 (79,325–84,393)], [0,123 (0,113–0,137)],
    [Duração do lote (s)], [69,925], [91,755 (88,370–94,460)], [89,749 (86,369–92,456)],
    [Fila pronta, máximo], [3], [3 (3–3)], [2 (2–2)],
    [Máximo de mensagens sem confirmação AMQP], [1], [1 (1–1)], [2 (2–2)],
    [Pico de CPU do grupo (%)], [830,810], [756,550 (673,600–803,450)], [754,277 (746,190–761,180)],
    [Pico de RAM do grupo (GB)], [3,051], [2,860 (2,848–2,869)], [4,252 (4,233–4,266)],
  ),
))

Confirmando o _trade-off_ previsto na matriz de efeitos, a média do pico de RAM subiu de 2,86 para 4,25 GB face à base repetida, enquanto as amplitudes dos picos de CPU se sobrepõem. O instrumento inicial aguardava a conclusão de A para observar B. O instrumento final consulta ambos em cada ronda. As diferenças de imagem Docker, limite de volumes do SeaweedFS, percurso HTTP/HTTPS e observação dos resultados limitam a comparação direta de durações e utilização de recursos entre séries.

Os valores finais de `QS-01` e `QS-02` correspondem à campanha da revisão `3cb1b74`, com os ensaios e dados individuais registados em `docs/sessoes/2026-11-24-validacao-final-3cb1b74.md`.

Em *operabilidade* (`QS-02`), o projeto A manteve o estado visível nas quatro ações de cada ensaio final. A navegação, o recarregamento e a reconexão registaram 3/3 recuperações cada, sem conclusões prematuras e com downloads HTTP 200 nos três ensaios. A baseline registou 6/12 nas mesmas quatro ações e 0/3 recuperações por navegação e por recarregamento. A reconexão explícita foi aferida na série final. A duração média das legendas passou de 6,029 para 7,243 s. Observaram-se 28 pedidos de API por ensaio na base e 40, 41 e 41 na revisão `3cb1b74`, com 6 pedidos de estado na base e 9 em cada ensaio final. Como a base registou zero eventos de progresso reconhecíveis, a comparação direta de duplicados e ordenação carece de observações equivalentes.

Num ensaio complementar com quatro pares sobre o mesmo vídeo de 10 s, uma consulta de estado por segundo acrescentou quatro pedidos e 1 048 bytes de corpo HTTP em quatro segundos. A mediana por pedido foi 7,75 ms. O ensaio quantificou o tráfego HTTP e a latência de um observador.

#pagebreak(weak: true)
== Ensaio complementar de elasticidade do vídeo

O controlador opcional, introduzido em `c4ddc6c`, consulta os pedidos em espera na fila `video_queue` e ajusta a escala de `video_tool` através do Docker Compose. Inicia-se com uma réplica e usa um máximo configurável, por omissão três. A redução da escala exige que os contadores de mensagens em espera e sem confirmação permaneçam a zero. Uma réplica que já tenha recebido trabalho publica a resposta terminal e confirma a mensagem antes de sair. O controlador corre no host, e a alocação de CPU e memória por réplica fica a cargo do operador.

O ensaio reutiliza a carga do QS-01. Mede a espera de B desde a submissão até ao início do primeiro vídeo e inclui a deteção da fila e o arranque da segunda réplica. O controlador consulta a fila a cada segundo, espera cinco segundos entre decisões e exige dez segundos de inatividade observada antes de reduzir a escala. A série principal começou com um aquecimento seguido de três ensaios válidos. Os controlos de uma e duas réplicas foram executados uma vez cada, na mesma pilha, com a mesma imagem, os mesmos dados e a mesma conta.

#tab([Espera de B no ensaio complementar de elasticidade],
  tabela(
    colunas: (1fr, 2cm, 3cm),
    [Configuração], [Ensaios], [Espera de B (s)],
    [Uma réplica fixa], [1], [69,917],
    [Duas réplicas fixas já ativas], [1], [0,099],
    [Escala automática, máximo três], [3], [7,902 em média (7,704–8,031)],
    [Escala automática, máximo duas], [1], [6,474],
  ),
)

Com máximo três, a escala passou de uma a três réplicas e regressou a uma em todos os ensaios. A e B produziram quatro vídeos descarregáveis após a redução, e as réplicas adicionais saíram com código zero. O retorno a uma réplica foi observado entre 32,8 e 36,9 s após a conclusão de A e B. Em média, decorreram 7,771 s da submissão de B ao arranque do contentor adicional e mais 0,131 s até ao início do trabalho. A espera média ficou abaixo do alvo de referência de 15 s. Este resultado caracteriza a carga A/B definida no protocolo. A campanha oficial de capacidade corresponde à revisão `3cb1b74`.

Numa prova separada, um pedido de saída durante uma legendagem permitiu que o mesmo trabalho concluísse antes de o contentor terminar com código zero. O resultado foi descarregado e descodificado na íntegra. O protocolo e os dados deste seguimento estão em `evaluation/README.md` e `docs/sessoes/2026-11-27-video-autoscaling.md`.

#pagebreak(weak: true)
== Preservação funcional

Em alinhamento com o método de _refactoring_, a preservação do comportamento externo foi verificada através de uma suíte de testes de auto-verificação e regressão. `R-01` a `R-04` passaram na validação de 22/11 com 38 testes Node, 76 testes do trabalhador de vídeo, 14 testes do instrumento e o _build_ de produção do frontend.

`QS-03` funcionou como verificação complementar de regressão da `DA-1` (`QS-01`), avaliando reentrega, integridade de resultado e limpeza após interrupção com dois consumidores na mesma fila. As primeiras provas revelaram ficheiros parciais órfãos após interromper um trabalhador e perda do trabalho em curso após reiniciar o RabbitMQ. Após as correções, as quatro provas retomaram o mesmo trabalho, publicaram um MP4 descarregável e deixaram zero novos ficheiros parciais. Os requisitos selecionados mantêm-se `QS-01` e `QS-02`; a suíte do trabalhador passou a 77 testes e a regressão de extração publicou quatro PNGs descarregáveis a partir de dois vídeos.

`F8` corrigiu uma falha herdada de reembolso da quota de vídeo ao cancelar, verificada separadamente com contas gratuitas (cancelamentos concorrentes, repetição após indisponibilidade temporária e projeto partilhado), uma vez que as campanhas principais usaram contas premium.

No seguimento de `F2` e `F3`, três regressões em MongoDB verificaram a preservação do estado terminal após edição e a aceitação de eventos pela ordem de cada vídeo. Pela API, renomear um projeto durante a execução preservou os dois resultados descarregáveis e o teste de reembolso voltou a passar (as medições comparativas acima pertencem à campanha imediatamente anterior a este seguimento).

Na revisão de código `c2f4a3f`, uma regressão detetada em Chromium foi corrigida: a lista de efeitos aplicados voltou a aparecer para titulares de um link de leitura. O ensaio confirmou a consulta pelo leitor, a remoção por um editor autorizado e a visibilidade da lista durante o processamento com os controlos de alteração bloqueados. Passaram 38 testes automatizados e a compilação de produção do frontend (`docs/sessoes/2026-11-27-applied-tools-read-only.md`).

#tab([Preservação funcional e testes de regressão],
  tabela(
    colunas: (2.4cm, 3.8cm, 2.8cm, 3.2cm, 1fr),
    tamanho: 8.5pt,
    [Zona alterada], [Testes de regressão existentes (`Tools/video/tests`, `projects/tests`, …)], [Lacunas de teste], [Testes acrescentados], [Resultado (imagem e vídeo)],
    [DA-1, orquestração], [`projects/tests`, `Tools/video/tests`], [Conclusões simultâneas, perda de resultados e órfãos em queda.], [Barreira controlada, prova com MongoDB e armazenamento reais (P-02) e interrupções QS-03.], [Dois resultados distintos descarregáveis; 4 PNGs na extração; zero órfãos em QS-03.],
    [DA-2, estado e frontend], [Testes do orquestrador e do estado no frontend.], [Tokens antigos, ordem, permissões e cancelamento durante navegação.], [Regressão A/B e F5 em Chromium; regressões F2/F3 em MongoDB.], [Primeira visita a estados terminais, permissões e respostas 204 e 409 verificadas.],
  ),
)

#tab([Riscos para a preservação funcional e mitigação],
  tabela(
    colunas: (3.4cm, 3.2cm, 4cm, 3.2cm),
    tamanho: 8.5pt,
    [Risco], [Funcionalidade afetada (imagem / vídeo)], [Mitigação], [Teste de regressão],
    [Perder resultados num fecho concorrente], [Vídeo e lotes mistos], [Atualização condicional atómica e verificação do lote.], [P-02 e regressão com MongoDB e armazenamento reais.],
    [Publicar resultados parciais após falha], [Imagem e vídeo], [Publicação condicionada ao estado do lote.], [Imagem só, vídeo só e lote misto com ZIP íntegro; falha em lote misto com zero resultados publicados.],
  ),
)
