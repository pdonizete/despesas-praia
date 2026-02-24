# Despesas da Praia (Flutter MVP)

App Android Flutter para controle **offline** de despesas com quantidade **dinâmica** de pessoas, com resumo de acerto e exportação em PDF.

## Funcionalidades
> Nota de teste conflito C/D: linha única consolidada para validar gatilho automático.


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

## Acessibilidade (leitor de tela)

Melhorias implementadas para tornar os fluxos principais mais acessíveis com TalkBack/VoiceOver:

- Inclusão de `Semantics` em elementos-chave das telas de despesas, resumo/acerto, configurações e cadastro de despesa.
- Rótulos e dicas (`label`/`hint`) em botões de ação (ex.: salvar, remover pessoa, exportar PDF, excluir despesa), com descrição clara da ação.
- Campos de formulário com contexto adicional para leitura por tecnologia assistiva (valor, parcelas, categoria, responsável, data e descrição).
- Itens de lista e cards do resumo com descrição completa para navegação linear via leitor de tela (valores, categoria, pagador, data e saldos).
- Função dedicada para construir descrição acessível de despesa (`buildExpenseItemSemanticsLabel`), incluindo cenários de parcelamento e descrição opcional.
- Teste automatizado cobrindo a geração do texto semântico da despesa para reduzir regressões de acessibilidade.

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
- A lista exibe um resumo visual no formato **"Mostrando X de Y despesas (Z%)"** quando existe ao menos uma despesa cadastrada, indicando quantas despesas estão visíveis após os filtros em relação ao total cadastrado.
- Quando não há despesas cadastradas, o comportamento é mantido sem percentual: **"Mostrando 0 de 0 despesas"**.

## Filtro por período na lista de despesas

A lista da tela principal também permite filtrar por período, com as opções:

- **Hoje**
- **7 dias**
- **30 dias**
- **Tudo**

Com isso, é possível visualizar rapidamente apenas as despesas mais recentes ou todo o histórico.

## Filtro por pagador na lista de despesas

A lista da tela principal também permite filtrar por **quem pagou** a despesa.

- A opção **Todos** remove o filtro de pagador e exibe despesas de qualquer pessoa.
- Quando um pagador selecionado deixa de existir (ex.: mudança na lista de pessoas), o filtro é normalizado automaticamente para **Todos**.

## Ordenação da lista de despesas

A lista da tela principal oferece opções de ordenação:

- **Data (desc)** — padrão
- **Valor (desc)**
- **Valor (asc)**

Os filtros convivem com a ordenação no seguinte pipeline:

1. **Período**
2. **Categoria**
3. **Pagador**
4. **Ordenação**

Assim, é possível combinar período + categoria + pagador e, em seguida, aplicar a ordenação sobre o resultado filtrado.

### Persistência da ordenação escolhida

A ordenação selecionada é salva localmente no dispositivo. Ao fechar e reabrir o app, a lista mantém automaticamente a última ordenação usada.
