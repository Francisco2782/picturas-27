#import "../template.typ": *

= Conclusões e Recomendações

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 6 do _template_.

  Sintetizem os contributos do relatório, sem repetir o conteúdo dos capítulos anteriores: o que o diagnóstico concluiu
  sobre a adequação do padrão atual, que otimizações sugerem e que considerações ficam para a evolução futura.

  Terminem com o que ficou por fazer e porquê (e.g., valores-alvo não atingidos, hipóteses por confirmar) e com a
  ligação à Fase 3: de que forma o _refactoring_ facilita, ou não, a integração de novas funcionalidades. Sejam realistas e honestos quanto às limitações da
  análise e às hipóteses que ficaram por confirmar.
]

== Adequação do padrão atual (global e do vídeo)

O trabalho desenvolvido na Fase 2 demonstrou a maturidade e a adequação do padrão global de *Microsserviços Orientados a Eventos* adotado pelo PictuRAS. A separação clara de responsabilidades por domínios de negócio (`users`, `projects`, `subscriptions`, `imageStorageService`), a proteção perimetral através de API Gateway com tokens JWT e a orquestração assíncrona suportada pelo _broker_ RabbitMQ constituem alicerces sólidos para sustentar operações concorrentes e isolar o utilizador das latências de computação em lote.

No domínio do vídeo, o diagnóstico arquitetural confirmou que a decisão herdada da Fase 1 de afastar o subsistema de vídeo do padrão distribuído das imagens — adotando um #strong[Pipeline Monolith sob Worker Assíncrono com passagem única] — foi tecnicamente acertada. A tentativa de decompor as transformações de vídeo em microsserviços isolados por filtro (como formulado na alternativa ALT-2) provocaria uma penalização catastrófica no comportamento temporal e no disco, resultante de sucessivas descodificações e recodificações com perdas em codecs H.264/AAC.

Contudo, a concretização original desse padrão continha duas fragilidades severas: a execução confinada a um único trabalhador com receção unitária (originando bloqueios inaceitáveis de fila) e a retenção do estado de execução na memória volátil do cliente sob uma janela modal obstrutiva. As decisões de _refactoring_ implementadas resolveram cirurgicamente estes estrangulamentos:
- #strong[DA-1 (Consumidores Concorrentes — TAT-01):] reduziu o tempo de espera do lote concorrente de 61,727 s para #strong[0,113 s], preservando a passagem única de codificação e os contratos de despacho existentes.
- #strong[DA-2 (Snapshot Atómico e Interface Desacoplada — TAT-04/05/06):] eliminou o bloqueio de ecrã e garantiu uma taxa de sucesso de #strong[12/12 ações (100%)] e #strong[3/3 em recuperação] após navegação, recarregamento e reconexão de rede, sem falsas conclusões.

== Sugestões de otimização

Com base nas evidências empíricas recolhidas ao longo dos ensaios, sugerem-se três otimizações práticas para a infraestrutura do sistema:
1. *Dimensionamento das réplicas de vídeo em produção:* Recomenda-se fixar duas réplicas do contentor `video_tool` por omissão no ambiente de implantação com recursos partilhados, acompanhado de um limite de memória de cerca de 3 GB por réplica para acomodar com margem segura os modelos Faster-Whisper.
2. *Debounce adaptativo na reconciliação de estado:* Implementar um mecanismo de _debounce_ dinâmico no cliente web que aumente o intervalo de _polling_ à rota `/processing-status` quando a ligação WebSocket estiver ativa e estável, reduzindo o tráfego HTTP sem comprometer a recuperação em falhas.
3. *Saneamento da infraestrutura de segurança interna:* Eliminar a dívida técnica herdada na comunicação entre microsserviços internos (`rejectUnauthorized: false` em certificados autoassinados expirados), adotando uma autoridade de certificação local automatizada.

== Considerações para evolução futura

A intervenção de _refactoring_ realizada na Fase 2 constitui um facilitador determinante para a evolução funcional futura da plataforma e para os desafios da Fase 3:
- *Contrato genérico de acompanhamento em segundo plano:* O modelo de snapshot atómico (`processingRun`) e a projeção segura de estado são inteiramente agnósticos em relação ao tipo de transformação. Qualquer nova ferramenta adicionada à plataforma no futuro beneficiará automaticamente de acompanhamento em tempo real, navegação livre no dashboard e resiliência a recarregamento acidental de página.
- *Robustez na orquestração de concorrência:* A correção das condições de corrida na consolidação de lotes (sessão P-02) e a gestão de estados terminais garantem que o orquestrador suporta a expansão para lotes híbridos complexos (misturando dezenas de imagens e vídeos com múltiplos efeitos) sem risco de corrupção ou perda de artefactos.
- *Aceleração por hardware:* Para cenários de produção com maior densidade de utilizadores, o subsistema de vídeo encontra-se preparado para incorporar aceleração por GPU (NVENC / CUDA / VideoToolbox) para as etapas de IA e transcodificação, sem necessidade de reestruturar a arquitetura de filas ou os fluxos de mensagens.

== Trabalho futuro

Reconhecem-se com rigor e transparência as seguintes limitações e passos pendentes:
- *Impacto de múltiplos clientes em concorrência:* Os testes de _polling_ quantificaram com sucesso o impacto de um único observador a 1 Hz (4 pedidos adicionais, 1048 bytes transferidos e 7,75 ms de latência mediana). A avaliação do impacto cumulativo na CPU e memória do MongoDB perante centenas de clientes em _polling_ simultâneo permanece como trabalho futuro.
- *Atribuição de recursos no host:* O acréscimo de 1,43 GB no pico agregado de memória RAM com duas réplicas ativas decorre primariamente da duplicação dos pesos do Faster-Whisper; a partilha de instâncias de modelo em memória partilhada (tática TAT-03) fica identificada como oportunidade futura de otimização de recursos.
- *Passos de encerramento da entrega:* Resta efetuar a reprodução independente das medições por outro elemento da equipa a partir do arquivo verificado `picturas-phase2-d01.tar.gz`, consolidar a revisão humana final do relatório e confirmar a calendarização administrativa com o corpo docente da unidade curricular.
