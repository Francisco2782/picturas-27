# PictuRAS · RAS 2026/2027 — Relatório da Fase 2 (Typst)

Fonte do rascunho do relatório do grupo PL3-G5. Inclui as medições finais, os testes de preservação funcional e o registo de utilização de IA. A revisão humana e a reprodução independente ficam por registar. [Sessão D-01 e D-02](../sessoes/2026-11-23-d01-d02.md)

O [PDF de pré-visualização](../template-fase2-preview.pdf) é um exemplo do template original. Para ver o relatório atual, compila `main.typ`.


## Compilar

Requer [Typst](https://typst.app) ≥ 0.13 (CLI) ou o editor web typst.app (carregar a pasta toda).

```bash
typst compile --font-path fonts main.typ      # gera main.pdf
typst watch   --font-path fonts main.typ      # recompila a cada gravação
```

A fonte usada é a **Carlito** (equivalente livre da Calibri, licença OFL), incluída em `fonts/`.

## Estrutura e correspondência com os exercícios

| Parte | Capítulo | Origem (template do exercício) |
|-------|----------|--------------------------------|
| I | 1 Introdução | — |
| II | 2 Âmbito e Vista da Arquitetura (explica o que é uma evidência `EV-nn`) | Ex. 6 Bloco 1, secções 0 e 1 |
| II | 3 Padrões Arquiteturais Atuais | Ex. 6 Bloco 1, secções 2.1 a 2.3 |
| II | 4 Alternativas e Matriz de Comparação (`ALT`) | Ex. 6 Bloco 1, secção 3 |
| III | 5 Trade-offs, Cenários de Qualidade e Prioridades (`QS`, a partir de fragilidades do sistema atual) | Ex. 6 Bloco 2, secção 4 (sem 4.1) |
| III | 6 Candidatos a Requisitos Não Funcionais (`CAND`) | Ex. 6 Bloco 2, secção 5 |
| IV | 7 Cenários de Entrada e Táticas Candidatas (`TAT`) | Ex. 7, secções 1 e 2 |
| IV | 8 Decisões Arquiteturais (`DA`) | Ex. 7, secção 3 |
| IV | 9 Vista Arquitetural Antes e Depois | Ex. 7, secção 4 |
| IV | 10 Trade-offs, Medição e Preservação Funcional (plano, resultados antes/depois, testes de regressão) | Ex. 7, secção 5; Ex. 6 Bloco 2, secção 6 (riscos); implementação |
| V | 11 Conclusões e Recomendações | Ex. 6 Bloco 2, secção 6 |
| V | 12 Utilização de IA | Ex. 6 Bloco 2, secção 7; Ex. 7, secção 6 |
| — | Anexos (instruções de execução, glossário) | — |

```
main.typ         capa, índices e ordem dos capítulos (editar autores/grupo aqui)
template.typ     estilos e componentes (tabela, tabela-campos, orientacao, preencher, …)
cover.typ        capa
capitulos/       um ficheiro por capítulo
images/          ee-um.png (capa); acrescentar aqui os diagramas da equipa
```

## Como rever o rascunho

1. Conferir as referências aos exercícios e preservar os IDs durante a revisão.
2. Recontar os resultados e repetir os cenários com o arquivo D-01. [Guia de reprodução](../../evaluation/phase2-reproduction.md)
3. Registar a revisão humana dos testes e da utilização de IA. Em `main.typ`, `#mostrar-orientacoes.update(true)` mostra as orientações do template.

## Componentes úteis

```typst
#tabela(colunas: (2cm, 1fr), [Cab. 1], [Cab. 2], [célula], [célula])   // 1.ª linha = cabeçalho
#tabela-campos([Campo], [Valor], [Campo], [Valor])                     // tabela chave/valor
#tab([Legenda], tabela(...))                                           // tabela numerada (Lista de Tabelas)
#paisagem[ ... ]                                                       // páginas na horizontal (tabelas largas)
```

Verificação final: `grep -rn "preencher\[" capitulos` não deve devolver nada.
