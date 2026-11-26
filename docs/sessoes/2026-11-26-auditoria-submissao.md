# Auditoria de submissão da Fase 2 · 26/11/2026

Árvore auditada: `fa46981`. Foi criado `RELATORIO_AUDITORIA.md` com matriz da v1, backlog, ensaios e checklist. O pedido começava na secção 6; a estrutura inicial foi inferida da auto-verificação pedida. As notas temporárias ficaram em `/tmp/audit_tmp/notas.md` porque `/audit_tmp` não existia e a raiz do sistema não é uma área de escrita do projeto.

| Comando ou grupo de comandos executados | Resultado |
|---|---|
| `git rev-parse HEAD`, `git status --short --branch`, `git diff --stat 3cb1b74..HEAD`, comparação da base com `afb84e5` nos componentes | Árvore inicial limpa. A alteração do worker após a campanha é apenas de documentação. Nenhum diff nos componentes comparados entre a base e o checkout de medição. |
| `pdftotext -layout docs/fase-2-guidelines.pdf -`, `pdftotext -layout docs/doc-ext-requisitos-2627.pdf -`, `pdfinfo evaluation/evidence/picturas-phase2-relatorio-rascunho.pdf`, extração de texto do rascunho | V1 adia regras formais. Extensão é da Fase 1. Rascunho local de 33 páginas contém 0,113 s. |
| `node --test projects/tests/*.test.js frontend/tests/processing-status.test.mjs` | 38 passaram. |
| `python3 -m pytest -p no:cacheprovider -q evaluation/tests`, `Tools/video/.venv/bin/python -m pytest -p no:cacheprovider -q Tools/video/tests` | 14 e 77 passaram com bytecode desativado. Um aviso do Pillow. |
| `docker compose config --quiet`, `docker build --progress=plain -t picturas-audit-frontend:fa46981 ./frontend` | Ambos passaram. Imagem local criada, etapa de build do Next em cache. |
| `sha256sum -c`, `tar -xzf`, `sha256sum --quiet -c SHA256SUMS` nos dois arquivos extraídos, `python3 verify_final.py`, `python3 evaluation/verify_phase2_evidence.py` | Procedimento integral na secção 2 do relatório. 45 e 141 entradas; 61,727085 s → 0,123429 s, 6/12 → 12/12, recuperações finais 3/3 em cada percurso. |
| `python3 docs/exercicios/check_citations.py`, `python3 -m pytest -p no:cacheprovider docs/exercicios/tests/ -q` | Códigos 2 e 4. Ficheiro e diretório ausentes. Conferência auxiliar com Python, expressão regular sobre citações literais e `git show 0523102:<caminho>`: 30 ocorrências, quatro caminhos abreviados. |
| `command -v typst`, `docker compose ps --status running --services`, `git check-ignore evaluation/evidence/picturas-phase2-final-3cb1b74.tar.gz` | Sem compilador local; stack corrente parcial; arquivo ignorado por Git. |

## Seguimento — prazo e relatório

- O utilizador indicou 27/11/2026 como prazo de entrega. A auditoria foi atualizada para registar essa data e manter por confirmar o comprovativo e as regras de formato.
- No capítulo 8, DA-1 agora distingue a campanha final de `3cb1b74` (0,123 s) da campanha anterior (0,113 s).
- O anexo agora descreve a obtenção do pacote final, validação dos checksums e recontagem, distinguindo-a da repetição ao vivo dos cenários.
- Compilação Typst não executada nesta máquina. A reprodução independente permanece pendente.

## Seguimento — citações dos exercícios

- Corrigidas as referências identificadas na auditoria nos slides de táticas e no template do Exercício 6. As citações de base apontam para a revisão `0523102`.
- Criado `docs/exercicios/check_citations.py`, que verifica caminhos e intervalos `ficheiro:linha` dos Markdown dos exercícios numa revisão Git selecionada, por omissão a base oficial.
- Criados testes para intervalos válidos, limites fora do ficheiro e intervalos invertidos.
- `python3 docs/exercicios/check_citations.py`: passou para todos os exercícios na revisão `052310226c51fa57a17101c7bd1ad795674aac95`.
- `python3 -m pytest -p no:cacheprovider docs/exercicios/tests/ -q`: 3 passaram.
- A revisão semântica de cada afirmação e a revisão humana integral continuam pendentes.

## Seguimento — justificação dos limiares

- O capítulo 6 esclarece que os limiares foram fixados na gate B-04 antes da implementação e explica a relação entre a baseline, os alvos e o mínimo operacional.
- O plano de decisões não regista uma justificação adicional baseada em limites de espera ou falhas aceitáveis para utilizadores. O texto assinala essa lacuna em vez de atribuir uma decisão não documentada à equipa.
- Confirmação da equipa sobre a fundamentação original permanece pendente.

## Seguimento — fonte de arquitetura herdada

- A tabela de artefactos da introdução e a lista de fontes do capítulo 2 agora indicam que `doc-sol-arquitetural.pdf` é mencionado nas diretrizes, mas não estava disponível. O relatório deixa de o apresentar como fonte consultada.
- A arquitetura herdada é descrita como analisada a partir do repositório de base e da documentação efetivamente disponível.
- `command -v typst` não encontrou o compilador nesta máquina. A compilação e a revisão visual continuam pendentes.

## Seguimento — registo de utilização de IA

- O capítulo 12 agora regista a contribuição Codex desta auditoria, os resultados aceites, o que não foi inferido e as verificações executadas.
- A redação identifica que os testes locais passaram e que a compilação Typst e a revisão humana não ocorreram nesta etapa.

As prioridades são confirmar o prazo e o formato, alinhar o relatório com o pacote final, obter revisão humana e documentar a reprodução independente. Os comandos e critérios de fecho constam das secções 2, 5 e 7. A aplicação não sofreu alterações.
