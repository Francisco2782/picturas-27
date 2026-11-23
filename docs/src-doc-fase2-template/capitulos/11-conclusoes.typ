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
A orquestração assíncrona mantém a execução em lote para imagem e vídeo. O serviço de vídeo agrupa o pipeline para reaproveitar a descodificação e codificação entre efeitos compatíveis. A fila comum admite consumidores concorrentes e a publicação de resultados exige proteção contra fechos simultâneos.

== Sugestões de otimização
A configuração validada para a carga de capacidade usa duas réplicas, e o Compose conserva uma por omissão. O dimensionamento para outras cargas precisa de observar em conjunto a espera dos trabalhos curtos, o pico de memória e a duração do lote.

== Considerações para evolução futura
O estado persistido permite acompanhar execuções longas através do mesmo endpoint após navegação, recarregamento ou reconexão. A evolução de ferramentas de vídeo pode reutilizar esse contrato de acompanhamento e os testes de regressão de lotes mistos.

== Trabalho futuro
O seguimento QS-03 validou a recuperação de uma execução de legendagem em dois tipos de interrupção. O teste de polling quantificou o custo HTTP de um observador. Cargas com vários clientes e a atribuição de CPU e memória ficam por avaliar. Para fechar a entrega, falta repetir os cenários por outro membro da equipa e registar a revisão humana do relatório e da utilização de IA.
