# Despesas da Praia (Flutter MVP)

App Android Flutter para controle **offline** de despesas entre 4 pessoas, com resumo de acerto e exportação em PDF.

## Funcionalidades

- 100% offline (sem login/sem backend)
- 4 pessoas fixas com nomes editáveis em Configurações
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
  - cota por pessoa (total/4)
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

- Chave `people`: nomes das 4 pessoas
- Chave `expenses`: lista de despesas serializadas em JSON

No Android, os arquivos ficam no diretório interno da aplicação (sandbox), persistindo entre aberturas do app.

## Parcelamento

- Cada despesa pode ser cadastrada com `parcelas` (inteiro, mínimo `1`, padrão `1`).
- Quando `parcelas > 1`, a despesa aparece como parcelada (ex.: `6x`) com valor por parcela na lista e no PDF.
- O cálculo de total geral, total por pessoa, cota e acertos continua usando o **valor total da despesa** (sem quebra mensal).
- Entradas antigas sem campo `parcelas` continuam válidas e são tratadas como `1`.

## Filtro por categoria na lista de despesas

- A lista da tela principal permite filtrar despesas por categoria para facilitar a visualização.
- A opção **"Todas"** remove o filtro e volta a exibir todas as despesas.
- O card de totais (total geral e total por pessoa) **não é afetado pelo filtro** e continua considerando todas as despesas cadastradas.
