# Draft de Release — PR #16 (rascunho)

Status: **DRAFT (não publicado)**

## Resumo
Refinamento visual no resumo da lista de despesas para incluir o percentual filtrado quando houver total de despesas maior que zero.

## Mudanças
- Resumo da lista agora exibe:
  - `Mostrando X de Y despesas (Z%)` quando `Y > 0`
  - `Mostrando 0 de 0 despesas` quando `Y = 0` (sem percentual)
- Ajuste de cálculo para percentual inteiro arredondado.
- Cobertura de testes para:
  - cenário com despesas e filtro aplicado;
  - cenário sem despesas (sem percentual).
- README atualizado com o novo comportamento.

## Validação
- Tentativa de execução local de `flutter analyze` e `flutter test` bloqueada por ausência do binário `flutter` no ambiente runner.
- CI da PR deve validar analyze/test em ambiente com Flutter instalado.

## Observações de publicação
- Sem criação de tag.
- Sem publicação de release real.
