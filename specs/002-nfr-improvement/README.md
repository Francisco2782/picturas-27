# Fase 2 — capacidade e operabilidade do PictuRAS

A espera média inicial de B foi de **61,727 s** com um worker. A configuração final usa duas réplicas de `video_tool` na mesma fila. O mínimo aceitável é ≤30 s e o alvo é ≤15 s.

Na medição inicial de operabilidade passaram **6/12 ações**, com **0/3** recuperações por navegação e **0/3** após refresh. O painel recuperável está implementado e aguarda validação integrada. A equipa ainda tem de medir os dois resultados finais.

Consultar a [especificação](spec.md), o [plano](plan.md), a [lista de tarefas](tasks.md) e a [auditoria e plano de correções](../../docs/fase-2-auditoria.md).
