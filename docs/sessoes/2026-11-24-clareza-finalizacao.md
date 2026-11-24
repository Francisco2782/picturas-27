# Clareza da finalização do lote

- O comentário de `persistAndSettleProcess` passou a explicar que duas respostas podem observar zero trabalhos pendentes em simultâneo. A atualização condicional permite que apenas uma confirme o lote.
- O avaliador passou a atribuir `Authorization` uma vez em `ApiClient._request`. O pedido conserva o mesmo valor `Bearer` e o mesmo cabeçalho de versão quando indicado.
- A análise anterior da reentrega entre a gravação do resultado e a remoção do trabalho continua uma hipótese sem ensaio específico. Os ensaios existentes interromperam jobs durante a legendagem. O âmbito desta sessão foi a clareza do código.

## Verificação

- `node --test projects/tests/process-batch.test.js` passou 9 testes. O Mongoose emitiu um aviso sobre um índice duplicado em `lastSeenAt`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m pytest -p no:cacheprovider -q evaluation/tests` passou 14 testes. Uma verificação direta com `unittest.mock` confirmou os cabeçalhos enviados com e sem JWT e com versão explícita.
- `git diff --check` passou. O diff face a `HEAD` do Dockerfile e da fonte Typst estava vazio.
