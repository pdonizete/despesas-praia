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
