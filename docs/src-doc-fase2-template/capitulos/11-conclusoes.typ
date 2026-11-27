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
A configuração validada em QS-01 usa duas réplicas, e o Compose conserva uma por omissão. A escala automática complementar reduziu a espera face ao controlo local com uma réplica fixa e voltou ao mínimo após o lote. Para outras cargas, convém medir a espera dos trabalhos curtos, o pico de memória e a duração do lote antes de escolher a escala.

== Considerações para evolução futura
Na Fase 3, novas ferramentas de vídeo podem reutilizar o contrato de acompanhamento das execuções longas após navegação, recarregamento ou reconexão. Os testes de regressão de lotes mistos dão à equipa uma forma de verificar se essas integrações preservam o processamento de imagens e vídeos.

== Âmbito da validação
O seguimento QS-03 verificou a recuperação de uma execução de legendagem após interrupções do worker e do broker. O teste de polling quantificou o tráfego HTTP de um observador. As conclusões aplicam-se às cargas, às réplicas e aos percursos registados nos ensaios locais.
