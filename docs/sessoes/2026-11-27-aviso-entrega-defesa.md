# Aviso dos docentes sobre a entrega e a defesa da Fase 2

Fonte: aviso dos docentes de 27/11/2026, transcrito na conversa.

## Entrega

- Prazo: **sexta-feira, 27 de novembro de 2026, às 23:59**.
- Percurso: **Conteúdo → Trabalho Prático → Fase 2 → Entrega Fase 2**.
- A página de submissão define a nomenclatura dos ficheiros e as avaliações individuais. Excluir artefactos de build, como `node_modules`.
- Submissões tardias são aceites com penalização de **1 valor por hora**, calculada ao minuto (1/60 de valor por minuto). Um atraso de 1 h 36 min implica 1,6 valores.

### Materiais a preparar

- **Relatório final da Fase 2.** Identificar a revisão de base e documentar os dois requisitos não funcionais, as metas, as medições antes e depois, as decisões de refactoring, as regressões e o uso de IA validado pela equipa.
- **Solução refatorada e testes.** O inventário da equipa prevê disponibilizar o código ou uma referência Git acessível, com a revisão identificada. O meio de entrega é definido na página de submissão.
- **Evidência reproduzível.** Incluir cenários, scripts, amostras, dados brutos, resultados e configuração do ambiente. O repositório descreve o pacote preparado e a verificação por checksum.
- **Avaliações individuais.** Seguir o procedimento definido na página de submissão.

As [diretrizes V1](../fase-2-guidelines.md) descrevem o conteúdo exigido e remetem o formato final para outra versão. O [inventário da equipa](../../RELATORIO_AUDITORIA.md#8-relatório-e-restantes-entregáveis--fase-5) identifica os materiais já preparados. Os nomes, formatos e a forma de anexar cada item dependem da página de submissão.

## Defesa

- **30 de novembro e 2 de dezembro de 2026**, no gabinete **DI 2.07**.
- Cada grupo agenda o horário através do Calendly indicado no aviso original. Os IDs de grupo são os mesmos da Fase 1.
- A apresentação dura **15 minutos**. O aviso sugere slides breves com 3 min para os dois requisitos não funcionais e a sua quantificação, 2 min para as alterações arquiteturais e de refactoring e 2 min para os resultados antes e depois face aos alvos. Segue-se uma demonstração de 3 min das melhorias na solução após refactoring.
- Preparar um único computador com os slides abertos, a aplicação e o browser em execução em segundo plano, os utilizadores já autenticados e os projetos, multimédia e ferramentas carregados.
- Todos os elementos do grupo devem estar junto ao gabinete **5 minutos antes** da hora agendada.
- Contactos: Miguel Regedor (`d14406@di.uminho.pt`) e Paulo Sousa (`d7157@di.uminho.pt`).

## Verificação

`git status --short --branch` confirmou uma árvore limpa antes da alteração. `rg` identificou as referências ao prazo anterior na auditoria e no estado de Fase 2. As novas datas foram conferidas com a mensagem transcrita. A nomenclatura detalhada, o procedimento de avaliação individual e o URL do Calendly ficaram na página de submissão ou no aviso original. A submissão efetiva e o horário reservado continuam por confirmar.
