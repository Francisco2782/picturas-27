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

 Os resultados arquivados demonstram a melhoria nos dois cenários exigidos, dentro das cargas e dos limites documentados. A orquestração global assíncrona por filas mantém o desacoplamento entre o cliente e o processamento em lote de imagem e vídeo, enquanto o _pipeline_ encapsulado em `video_tool` preserva a eficiência ao reutilizar a passagem de descodificação e codificação entre efeitos contíguos. O diagnóstico mostrou que a fragilidade não residia no modelo de comunicação por filas, mas na execução em consumidor único e na ausência de estado persistido para acompanhamento. Com consumidores concorrentes e proteção atómica do fecho de lote, o padrão atual responde adequadamente aos requisitos de capacidade sem exigir a fragmentação distribuída do _pipeline_ de vídeo. O ensaio de elasticidade e a gravação idempotente de resultados mostraram que o mesmo modelo acomoda também o ajuste dinâmico de réplicas e a repetição de entregas sem alterações estruturais.

== Sugestões de otimização

Para o cenário de capacidade medido, a configuração validada utiliza duas réplicas de `video_tool`, mantendo o `docker-compose.yaml` uma réplica por omissão. Para cargas variáveis, o controlador opcional de escala automática oferece uma alternativa que liberta as réplicas adicionais após o lote. A escolha deve ponderar a previsibilidade (réplicas fixas já ativas eliminam o tempo de arranque de contentores) face à poupança de recursos. A alocação de CPU e memória por réplica e a execução do controlador fora dos contentores continuam a cargo do operador. O dimensionamento para outras cargas deve equilibrar espera, pico de RAM e duração total do lote, avaliando a separação por perfil de carga (`ALT-3`) apenas se a contenção voltar a crescer.

== Considerações para evolução futura

- *Produção do controlador de elasticidade:* integrar a sua configuração no Compose, definir limites de recursos por réplica e validar com perfis de carga mistos.
- *Acompanhamento por _push_:* se o custo do _polling_ com múltiplos clientes se revelar relevante, o `ws_gateway` existente permite emitir progresso por _push_ em vez de consultas HTTP repetidas.
- *Partição de filas por prioridade de plano:* uma fila dedicada a _premium_ e outra comum a _free_ e anónimos evitaria que cargas gratuitas competissem com cargas pagas pelos mesmos _workers_, complementando a separação por perfil de carga (`ALT-3`).
- *Aceleração por hardware no contentor de vídeo:* GPU/NVENC ou VideoToolbox pode acelerar a transcodificação H.264 e o Faster-Whisper, reduzindo a duração das legendagens longas que dominam o cenário de capacidade.

== Trabalho futuro

Os seguimentos registados no capítulo 10 fecharam as verificações técnicas planeadas para os cenários avaliados. Permanecem, contudo, questões fora desse âmbito:

- A hipótese `H-02` (contenção de I/O no volume partilhado `image_data`) não foi confirmada nem refutada, porque as cargas dos cenários validados não a exerceram de forma perceptível. A sua verificação exige uma experiência de concorrência elevada sobre o volume.
- O custo do _polling_ em CPU e memória com múltiplos clientes simultâneos não foi medido: o ensaio quantificou apenas o custo HTTP de um observador e não estabeleceu efeito no tempo de conclusão.
- A janela entre o _upload_ de um resultado e a gravação do respetivo registo no MongoDB ainda pode deixar um objeto órfão no armazenamento, porque as duas operações não são transacionais. A correção da reentrega cobriu apenas a janela entre gravação e remoção do trabalho.

Quanto à ligação à Fase 3, ao desacoplar o estado de execução no MongoDB (`processingRun`) da interface cliente e consolidar uma suíte de testes de auto-verificação sobre lotes simples e mistos, o _refactoring_ facilita a integração de novas funcionalidades: novas ferramentas ou operações de vídeo podem reutilizar o mesmo contrato tipado de progresso e o mecanismo de recuperação após navegação, recarregamento ou reconexão, sem reintroduzir acoplamento à UI. A gravação idempotente de resultados torna seguras as reentregas e a repetição de trabalhos, e o encerramento controlado da réplica permite que a escala evolua sem perder trabalho em curso. Em contrapartida, cada nova funcionalidade de vídeo percorre mais caminhos concorrentes e sensíveis a permissões, pelo que as evoluções futuras devem manter e alargar os testes de regressão criados nesta fase.
