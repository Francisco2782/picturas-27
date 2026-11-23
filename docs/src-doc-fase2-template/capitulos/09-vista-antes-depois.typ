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

#figure(kind: image,
  raw("Browser [overlay, estado React] ← Socket.IO ← projects\nprojects → video_queue → video_tool [uma réplica]\nvideo_tool → project_queue → projects → armazenamento", block: true),
  caption: [Vista arquitetural antes das decisões DA-1 e DA-2],
)

== Depois

#figure(kind: image,
  raw("Browser [painel no layout] ← Socket.IO ← projects ↔ MongoDB [snapshot]\nBrowser → gateway → projects [consulta autenticada de estado]\nprojects → video_queue → video_tool [duas réplicas no ensaio]\nworkers → project_queue → projects [fecho seguro] → armazenamento", block: true),
  caption: [Vista arquitetural depois das decisões DA-1 e DA-2],
)

== Legenda e notas

As setas indicam a direção das chamadas ou mensagens. Os rótulos entre parênteses retos mostram as opções de implantação ou os pontos do refactoring. DA-1 intervém no consumo e no fecho do lote. DA-2 intervém na persistência e na leitura do estado.
