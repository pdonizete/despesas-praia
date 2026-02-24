# Despesas da Praia (Flutter MVP)

App Android Flutter para controle **offline** de despesas com quantidade **dinâmica** de pessoas, com resumo de acerto e exportação em PDF.

## Funcionalidades
> Nota de teste conflito resolvido: mantida a nota B para validar a PR.


- 100% offline (sem login/sem backend)
- Pessoas dinâmicas: adicione/remova participantes em Configurações e edite os nomes
- Cadastro de despesas com:
  - valor (R$)
  - categoria (Alimentação, Mercado, Transporte, Passeio, Outros)
  - quem pagou
  - data
  - descrição opcional
- Tela principal com:
  - lista de despesas ordenada por data (desc)
  - total geral
  - total por pessoa
- Tela Resumo/Acerto com:
  - cota por pessoa (total/número de pessoas)
  - saldo por pessoa
  - sugestão de transações (devedores -> credores)
- Exportação de PDF + compartilhamento (WhatsApp/share sheet Android)

## Como rodar

```bash
/opt/flutter/bin/flutter pub get
/opt/flutter/bin/flutter run
```

## Como gerar APK release

```bash
/opt/flutter/bin/flutter build apk --release
```

APK gerado em:

`build/app/outputs/flutter-apk/app-release.apk`

## Persistência local (Hive)

Os dados são salvos localmente via **Hive** em uma box chamada `despesas_praia`.

- Chave `people`: lista de nomes das pessoas cadastradas
- Chave `expenses`: lista de despesas serializadas em JSON

No Android, os arquivos ficam no diretório interno da aplicação (sandbox), persistindo entre aberturas do app.

## Gestão dinâmica de pessoas

- O app exige ao menos **1 pessoa** cadastrada.
- É possível adicionar novas pessoas e remover pessoas existentes em Configurações.
- Ao remover uma pessoa que **não possui despesas**, a remoção é direta.
- Ao remover uma pessoa que **possui despesas**, é obrigatório escolher outra pessoa para reatribuição antes de concluir.
- Regra de reatribuição/índices:
  - despesas da pessoa removida passam para a pessoa escolhida;
  - após a remoção, os índices das pessoas que estavam depois da removida são ajustados automaticamente para manter consistência.

## Parcelamento

- Cada despesa pode ser cadastrada com `parcelas` (inteiro, mínimo `1`, padrão `1`).
- Quando `parcelas > 1`, a despesa aparece como parcelada (ex.: `6x`) com valor por parcela na lista e no PDF.
- O cálculo de total geral, total por pessoa, cota e acertos continua usando o **valor total da despesa** (sem quebra mensal).
- Entradas antigas sem campo `parcelas` continuam válidas e são tratadas como `1`.

## Filtro por categoria na lista de despesas

- A lista da tela principal permite filtrar despesas por categoria para facilitar a visualização.
- A opção **"Todas"** remove o filtro e volta a exibir todas as despesas.
- O card de totais (total geral e total por pessoa) **não é afetado pelo filtro** e continua considerando todas as despesas cadastradas.

## Ordenação da lista de despesas

A lista da tela principal oferece opções de ordenação:

- **Data (desc)** — padrão
- **Valor (desc)**
- **Valor (asc)**

O filtro por categoria e a ordenação convivem: você pode aplicar um filtro e, ao mesmo tempo, escolher a ordenação da lista.

### Persistência da ordenação escolhida

A ordenação selecionada é salva localmente no dispositivo. Ao fechar e reabrir o app, a lista mantém automaticamente a última ordenação usada.

## Entrega recente: compartilhamento de sinopse na HomeScreen

A documentação desta entrega inclui os pontos implementados no fluxo de compartilhamento da sinopse:

- Integração com `share_plus` para abrir o share sheet nativo (WhatsApp, Telegram e outros apps compatíveis).
- Botão de compartilhar no `AppBar` e também na área de resultado, com `Semantics` e `tooltip` para acessibilidade.
- Tratamento de cenário sem filme carregado: ao tentar compartilhar sem conteúdo, o app exibe `SnackBar` orientativo.
- Extração de função utilitária para montar o texto de compartilhamento com título, ano e sinopse.
- Atualização de testes (widget e unitário) para cobrir o novo comportamento de compartilhamento.

### Validação crítica da entrega

Validação executada no branch `feat/share-sinopse-03584bec`, com verificação completa de qualidade e build:

- `flutter analyze` (lint)
- `flutter test`
- `flutter build apk --release`

Para ambientes em que `flutter` não está no `PATH`, foi utilizado fallback explícito para `/opt/flutter/bin/flutter`.
