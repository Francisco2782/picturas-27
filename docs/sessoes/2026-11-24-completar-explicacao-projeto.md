# Atualização da explicação do projeto

- Atualizei `docs/EXPLICACAO_PROJETO.md` a partir da baseline e do registo de validação da revisão `3cb1b74`. O resumo, a cronologia e as tabelas distinguem os resultados finais dos valores históricos de 22/11 e de `fb18924`.
- Completei o fluxo de resultados no RabbitMQ, a proteção perante reentrega, a forma do snapshot de progresso e o contrato de consulta do estado. Corrigi referências antigas a testes e distingui os ensaios simulados, os testes em MongoDB e as regressões pela API com armazenamento real.
- Substituí o plano histórico de redação pelo estado observado do código, do pacote experimental e do rascunho. Registei 27/11/2026 como o prazo comunicado pela equipa e preservei a referência histórica da V1. A revisão humana e a reprodução independente continuam por registar.

## Verificação

- Comparei as tabelas com os CSV de capacidade e Chromium da revisão final. Um script Python verificou 33 ligações Markdown, os delimitadores dos blocos de código e as médias principais contra os CSV. Conferi os percursos de recuperação e a ausência de conclusões prematuras nos três ensaios medidos.
- `sha256sum -c picturas-phase2-final-3cb1b74.tar.gz.sha256` confirmou o pacote citado. `git diff --check` passou. A consulta ao código e a `git show phase2-base:Tools/video/video_processor.py` confirmou os caminhos e o uso de temporários de vídeo na baseline.
- A atualização é documental. O código, o Dockerfile, a fonte Typst e os dados do pacote final foram preservados.
