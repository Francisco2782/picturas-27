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

Para ilustrar de forma comparável o impacto estrutural e operacional das decisões arquiteturais DA-1 e DA-2, apresentam-se as vistas arquiteturais do fluxo de processamento de vídeo antes e depois da intervenção de _refactoring_.

== Antes


Na versão de base herdada da Fase 1, o processamento de vídeo sofria de acoplamento temporal na interface e de serialização forçada no motor de execução, conforme ilustrado no diagrama da @fig-vista-antes.

#figure(
  block(
    fill: luma(248),
    inset: 12pt,
    radius: 4pt,
    stroke: 0.5pt + luma(200),
    align(left, text(size: 8pt, font: "Courier", [
```
[ Navegador / Next.js SPA ] ──(Bloqueado por Modal Overlay)──> (Estado Volátil em React State)
        │
        │ POST /api-gateway/projects/:user/:project/process
        ▼
[ API Gateway (Express) ] ─────> [ Projects :9001 (Orquestrador) ] ──(1 msg/vídeo)──> [ RabbitMQ: video_queue ]
                                                                                              │
                                                                                              ▼ (prefetch=1)
                                                                             [ video_tool (1 Réplica Única) ]
                                                                             (Execução serializada bloqueante)
```
    ]))
  ),
  caption: [Vista arquitetural antes das decisões DA-1 e DA-2],
) <fig-vista-antes>

#figure(kind: image,
  raw("Browser [overlay, estado React] ← Socket.IO ← projects\nprojects → video_queue → video_tool [uma réplica]\nvideo_tool → project_queue → projects → armazenamento", block: true),
    caption: [Vista arquitetural antes das decisões DA-1 e DA-2],
) 

== Depois

Após a aplicação das decisões arquiteturais DA-1 e DA-2, a interface passa a ser não bloqueante e resiliente a falhas de rede, enquanto a fila de vídeo distribui a carga por trabalhadores concorrentes, como representado na @fig-vista-depois.

#figure(
  block(
    fill: luma(248),
    inset: 12pt,
    radius: 4pt,
    stroke: 0.5pt + luma(200),
    align(left, text(size: 7.5pt, font: "Courier", [
```
[ Navegador / Next.js SPA ] ──(Painel Flutuante Não Bloqueante)──> [ Sincronização: Polling REST + Socket.IO ]
        │                                                                             │
        │ Navegação livre entre projetos e páginas                                    ▼ «tática: TAT-04/06»
        │                                                            [ Projects: processingRun (MongoDB) ]
        ▼ POST …/process                                                              │
[ API Gateway (Express) ] ─────> [ Projects :9001 (Orquestrador) ] ───────────────────┼──> [ RabbitMQ: video_queue ]
                                         ▲                                            │            │
                                         │ basic_ack manual                           │            │
                                         └─────────────────────────────┐              ▼            ▼ (prefetch=1)
                                                                       │       «tática: TAT-01»   «tática: TAT-01»
                                                       (Commit Seguro) │       [ video_tool: 1 ]  [ video_tool: 2 ]
                                                                       └───────(Processa A)       (Processa B)
```
    ]))
  ),
  caption: [Vista arquitetural depois das decisões DA-1 e DA-2],
) <fig-vista-depois>

#figure(kind: image,
  raw("Browser [painel no layout] ← Socket.IO ← projects ↔ MongoDB [snapshot]\nBrowser → gateway → projects [consulta autenticada de estado]\nprojects → video_queue → video_tool [duas réplicas no ensaio]\nworkers → project_queue → projects [fecho seguro] → armazenamento", block: true),
    caption: [Vista arquitetural depois das decisões DA-1 e DA-2],
)

== Legenda e notas

=== Comparação sistemática dos elementos alterados

Na @tab-comparacao-antes-depois, sintetizam-se as diferenças estruturais introduzidas em cada ponto do sistema pelas táticas de desenho de software.

#tab([Matriz comparativa de elementos arquiteturais Antes e Depois],
  tabela(
    colunas: (3.2cm, 4cm, 4.4cm, 1fr),
    tamanho: 8.5pt,
    [Ponto arquitetural], [Antes (Baseline oficial)], [Depois (Refactoring)], [Táticas associadas e benefício],
    [Interação na Interface Web], [Janela modal sobreposta que bloqueia todas as rotas da aplicação durante o lote.], [Painel flutuante desacoplado e persistente no layout comum do Dashboard.], [«tática: TAT-05» — Permite ao utilizador editar outros projetos durante a execução.],
    [Ciclo de Vida do Estado], [Estado de progresso reside apenas na memória volátil do componente React.], [Snapshot atómico persistido na coleção `Project` no MongoDB (`processingRun`).], [«tática: TAT-04» — Resiliência total a recarregamento de página (F5) e navegação.],
    [Sincronização de Progresso], [Apenas escuta passiva de eventos através do gateway Socket.IO.], [Sincronização mista: push via Socket.IO e chamadas autenticadas com debounce à API de status.], [«tática: TAT-06» — Validação monotónica de progresso e tratamento de perdas de rede.],
    [Concorrência na Fila AMQP], [Uma única réplica de `video_tool` com prefetch unitário (serialização total).], [Duas réplicas concorrentes consumindo da mesma fila durável `video_queue`.], [«tática: TAT-01» — Elimina o bloqueio de cabeça de fila; lote B arranca em 0,113 s.],
    [Finalização de Lotes], [Vulnerabilidade a perda de resultados no fecho concorrente (defeito F1).], [Sincronização atómica com barreira condicional e validação de tokens de execução.], [Garante a integridade dos dados e entrega de todos os ficheiros gerados no lote.],
  ),
) <tab-comparacao-antes-depois>

=== Notas explicativas

- As setas sólidas indicam o fluxo de pedidos HTTP síncronos e chamadas REST autorizadas via JSON Web Token (JWT).
- As setas tracejadas representam a transmissão assíncrona de eventos e mensagens via RabbitMQ AMQP e Socket.IO.
- Os estereótipos `«tática: TAT-nn»` identificam explicitamente os componentes onde cada tática formal de arquitetura foi materializada no código.
- As anotações entre parênteses retos delimitam as fronteiras de contentores e processos Docker isolados.
- Todas as alterações preservaram estritamente o contrato de dados das mensagens e as interfaces públicas da API Gateway, assegurando compatibilidade funcional absoluta com os restantes microsserviços de negócio da plataforma.
