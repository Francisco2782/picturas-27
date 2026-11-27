#import "../template.typ": *

= Vista Arquitetural Antes e Depois

#orientacao[
  *Origem:* Exercício 7, secção 4 do _template_.

  Duas vistas do mesmo diagrama: *antes* e *depois* das decisões. Usem o tipo de diagrama que melhor mostrar a alteração
  (componentes, implantação ou sequência). Destaquem os elementos ou as interações introduzidos ou alterados pelas
  táticas (com um estereótipo `«tática: …»` ou uma cor) e incluam uma *legenda*.

  As duas vistas devem ser comparáveis: mesma notação, mesma escala e os mesmos elementos de contexto, de modo a que a
  diferença se perceba a olho. A legenda e as notas explicam o que mudou entre elas e porquê.
]

== Antes

#figure(
  image("../images/vista_antes.svg", width: 95%),
  caption: [Vista arquitetural antes das decisões DA-1 e DA-2],
) <fig-vista-antes>

== Depois

#figure(
  image("../images/vista_depois.svg", width: 95%),
  caption: [Vista arquitetural depois das decisões DA-1 e DA-2],
) <fig-vista-depois>

== Legenda e notas

*Ferramenta / notação:* Graphviz (fontes em `images/vista_antes.dot` e `images/vista_depois.dot`). Vista esquemática de componentes e fluxos em tempo de execução.

As setas indicam o sentido das chamadas HTTPS/WebSocket ou das mensagens AMQP, e as filas pertencem à exchange `picturas`. As duas vistas usam a mesma notação e os mesmos elementos de contexto. A diferença entre @fig-vista-antes e @fig-vista-depois é percebida a olho.

#tab([Legenda dos destaques das vistas antes/depois],
  tabela(
    colunas: (5.5cm, 1fr),
    [Elemento (cor, estilo)], [Significado],
    [Contorno vermelho (vista de @fig-vista-antes)], [Fragilidade observada na solução de base, correspondendo à evidência `EV-04`/`EV-05`/`EV-08` e `EV-10` da tabela de candidatos.],
    [Contorno e fundo laranja], [Elemento introduzido ou modificado pelas táticas, assinalado com o estereótipo `«tática: TAT-nn»` (apenas na vista de @fig-vista-depois).],
    [Caixas amareladas], [Filas RabbitMQ da exchange `picturas` (presentes nas duas vistas).],
    [Seta tracejada laranja], [Nova interação: consulta autenticada de estado (`TAT-04`).],
  ),
)

- *O que mudou com DA-1 (`TAT-01`)*: o consumo de `video_queue` passa a admitir réplicas concorrentes (`video_tool`), e o orquestrador `projects` passa a proteger atomicamente o fecho do lote e a limpar ficheiros temporários por saída.
- *O que mudou com DA-2 (`TAT-04`, `TAT-05`, `TAT-06`)*: o progresso deixa de seguir diretamente do trabalhador para `ws_queue`, passando a ser validado e persistido em `projects` (`processingRun` no MongoDB) antes da difusão por Socket.IO; na interface, o _overlay_ bloqueante dá lugar a um painel global desacoplado com reconciliação sobre a rota autenticada de estado.

