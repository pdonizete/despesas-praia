# Release Draft (não publicado)

## Título sugerido
`vNext - Resumo de contagem de despesas filtradas`

## Escopo
Entrega da feature de resumo visual de contagem de despesas na lista principal, indicando o total visível após filtros versus total cadastrado.

## Incluído nesta PR (#15)
- Feature: exibição de **"Mostrando X de Y despesas"** na tela de despesas.
- Teste widget cobrindo o resumo visual com e sem filtro de categoria.
- Documentação atualizada no README descrevendo o comportamento do resumo.

## Validação
- `flutter analyze`: sem issues.
- `flutter test`: suíte passando, incluindo o novo teste de resumo visual.

## Riscos conhecidos
- O novo teste interage com dropdown de categoria; alterações futuras no texto dos rótulos podem exigir ajuste no teste.

## Rollout
- Sem migração de dados.
- Sem flags.
- Publicação padrão da próxima versão do app.

## Observações operacionais
- **Sem merge realizado**.
- **Sem criação de tag/release real**.
- Draft apenas textual para uso na etapa de release.
