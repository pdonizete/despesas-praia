# Despesas da Praia (Flutter MVP)

[![CI](https://github.com/pdonizete/despesas-praia/actions/workflows/ci.yml/badge.svg)](https://github.com/pdonizete/despesas-praia/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/pdonizete/despesas-praia?include_prereleases&sort=semver)](https://github.com/pdonizete/despesas-praia/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.11+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/github/license/pdonizete/despesas-praia)](https://github.com/pdonizete/despesas-praia/blob/main/LICENSE)

App Android Flutter para controle **offline** de despesas com quantidade **dinâmica** de pessoas, com resumo de acerto e exportação em PDF.

## 📱 Screenshots

| Tela Principal | Tela de Resumo |
|:--:|:--:|
| *(em breve)* | *(em breve)* |
| Lista de despesas com filtros | Acerto e sugestão de transações |

## ✨ Funcionalidades

- 100% offline (sem login/sem backend)
- Pessoas dinâmicas: adicione/remova participantes em Configurações e edite os nomes
- Cadastro de despesas com:
  - valor (R$)
  - categoria (Alimentação, Mercado, Transporte, Passeio, Outros)
  - quem pagou
  - data
  - descrição opcional
  - parcelamento
- Tela principal com:
  - lista de despesas ordenada por data (desc)
  - filtros por período, categoria e pagador
  - ordenação configurável (data, valor)
  - total geral
  - total por pessoa
- Tela Resumo/Acerto com:
  - cota por pessoa (total/número de pessoas)
  - saldo por pessoa
  - sugestão de transações (devedores → credores)
- Exportação de PDF + compartilhamento (WhatsApp/share sheet Android)

## ♿ Acessibilidade (leitor de tela)

Melhorias implementadas para tornar os fluxos principais mais acessíveis com TalkBack/VoiceOver:

- Inclusão de `Semantics` em elementos-chave das telas de despesas, resumo/acerto, configurações e cadastro de despesa.
- Rótulos e dicas (`label`/`hint`) em botões de ação (ex.: salvar, remover pessoa, exportar PDF, excluir despesa), com descrição clara da ação.
- Campos de formulário com contexto adicional para leitura por tecnologia assistiva (valor, parcelas, categoria, responsável, data e descrição).
- Itens de lista e cards do resumo com descrição completa para navegação linear via leitor de tela (valores, categoria, pagador, data e saldos).
- Função dedicada para construir descrição acessível de despesa (`buildExpenseItemSemanticsLabel`), incluindo cenários de parcelamento e descrição opcional.
- Teste automatizado cobrindo a geração do texto semântico da despesa para reduzir regressões de acessibilidade.

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Despesas da Praia                        │
│                   (Flutter Mobile App)                      │
├─────────────────────────────────────────────────────────────┤
│  UI Layer          │  Flutter Widgets + Material Design 3   │
│  (Interface)       │  Responsivo, acessível, offline        │
├────────────────────┼────────────────────────────────────────┤
│  State Management  │  ChangeNotifier + InheritedWidget      │
│  (Estado)          │  AppState centralizado                 │
├────────────────────┼────────────────────────────────────────┤
│  Business Logic    │  Models: Expense, Category, Settlement │
│  (Regras)          │  Cálculos de acerto, filtros, sorts    │
├────────────────────┼────────────────────────────────────────┤
│  Data Layer        │  Hive (NoSQL local)                    │
│  (Persistência)    │  100% offline, zero backend            │
├────────────────────┼────────────────────────────────────────┤
│  Export            │  PDF (pdf package) + Share             │
│  (Compartilhamento)│  Exporta resumo para WhatsApp/email    │
└─────────────────────────────────────────────────────────────┘
```

### Tecnologias Principais

| Camada | Tecnologia | Por quê? |
|--------|------------|----------|
| **Framework** | Flutter 3.11+ | Multiplataforma, performance nativa |
| **Persistência** | Hive | Leve, rápido, sem backend |
| **PDF** | pdf package | Geração local, sem serviços externos |
| **IDs** | uuid | Únicos, offline-safe |
| **Formatação** | intl | Moeda (R$), datas localizadas |

### Pipeline de Entrega

```
Código → CI (flutter analyze + test) → Tag v*.*.* → Release (APK)
  ↑                                                          ↓
  └────────────────── GitHub Actions ────────────────────────┘
```

- **CI em todo push**: análise estática + testes automatizados
- **Release por tag**: build do APK assinado + publicação automática
- **Testes**: Widget tests, unit tests, acessibilidade

## 👨‍💻 Como Foi Construído

> **"Este projeto foi concebido e dirigido por mim com apoio de agentes de IA.**  
> **Eu defini requisitos, fluxos, critérios de aceite, acessibilidade e pipeline de entrega."**

### O Problema

Viagens em grupo são divertidas — dividir as contas, nem tanto. Sempre sobra alguém no prejuízo, alguém que esquece de pagar, ou aquela planilha do WhatsApp que ninguém atualiza.

**Minha solução:** Um app 100% offline, que não depende de login, internet ou servidor. Funciona na praia, na chácara, no meio do mato. Só precisa do celular.

### O Processo

**1. Produto (Eu)**
- Defini o escopo MVP: despesas, pessoas dinâmicas, acerto automático, PDF
- Priorizei acessibilidade desde o início (TalkBack/VoiceOver)
- Especifiquei cada tela, cada fluxo, cada validação

**2. Arquitetura (Eu + Agentes IA)**
- Escolhi Flutter + Hive para ser realmente offline
- Estruturei em camadas: UI → State → Models → Storage
- Configurei CI/CD no GitHub Actions desde o PR #1

**3. Implementação (Agentes IA sob minha direção)**
- Código Flutter estruturado, testado, documentado
- Refatorações guiadas por code review automatizado
- Correções de bugs identificados em auditoria (4 fixes críticos na v1.1.1)

**4. Validação (Eu + CI)**
- `flutter analyze` sem warnings
- `flutter test` passando (widgets, unidade, acessibilidade)
- Testes manuais em dispositivo físico

### O Que Me Diferencia

Não é só "um app de despesas". É:

- **Acessível por design**: Semantics, labels, hints, testes automatizados de acessibilidade
- **Engenharia de software**: CI/CD, testes, releases automatizadas, código limpo
- **Produto maduro**: Resolução de problema real, foco em UX, iteração contínua

### Evidências no Repositório

- ✅ 54+ commits com história clara
- ✅ 6 Pull Requests revisados e documentados
- ✅ 4 workflows GitHub Actions (CI, Release, Screenshots)
- ✅ Testes automatizados rodando em cada push
- ✅ Releases publicadas com APK pronto para instalar

## 🚀 Download

Baixe o APK mais recente na página de [Releases](https://github.com/pdonizete/despesas-praia/releases).

## 🛠️ Como Rodar

```bash
flutter pub get
flutter run
```

## 📦 Como Gerar APK Release

```bash
flutter build apk --release
```

APK gerado em: `build/app/outputs/flutter-apk/app-release.apk`

## 💾 Persistência Local (Hive)

Os dados são salvos localmente via **Hive** em uma box chamada `despesas_praia`.

- Chave `people`: lista de nomes das pessoas cadastradas
- Chave `expenses`: lista de despesas serializadas em JSON
- Chave `expenseSortOption`: ordenação preferida da lista

No Android, os arquivos ficam no diretório interno da aplicação (sandbox), persistindo entre aberturas do app.

## 👥 Gestão Dinâmica de Pessoas

- O app exige ao menos **1 pessoa** cadastrada.
- É possível adicionar novas pessoas e remover pessoas existentes em Configurações.
- Ao remover uma pessoa que **não possui despesas**, a remoção é direta.
- Ao remover uma pessoa que **possui despesas**, é obrigatório escolher outra pessoa para reatribuição antes de concluir.
- Regra de reatribuição/índices:
  - despesas da pessoa removida passam para a pessoa escolhida;
  - após a remoção, os índices das pessoas que estavam depois da removida são ajustados automaticamente para manter consistência.

## 💳 Parcelamento

- Cada despesa pode ser cadastrada com `parcelas` (inteiro, mínimo `1`, padrão `1`).
- Quando `parcelas > 1`, a despesa aparece como parcelada (ex.: `6x`) com valor por parcela na lista e no PDF.
- O cálculo de total geral, total por pessoa, cota e acertos continua usando o **valor total da despesa** (sem quebra mensal).
- Entradas antigas sem campo `parcelas` continuam válidas e são tratadas como `1`.

## 🔍 Filtros e Ordenação

### Filtros Disponíveis

| Filtro | Opções |
|--------|--------|
| **Período** | Hoje, 7 dias, 30 dias, Tudo |
| **Categoria** | Todas, Alimentação, Mercado, Transporte, Passeio, Outros |
| **Pagador** | Todas as pessoas cadastradas |

### Ordenação

- **Data (desc)** — padrão
- **Valor (desc)**
- **Valor (asc)**

Pipeline de processamento: Período → Categoria → Pagador → Ordenação

A ordenação selecionada é persistida entre sessões.

## 🎯 Roadmap

- [ ] Backup/restore de dados (export/import JSON)
- [ ] Dark mode
- [ ] Categorias personalizáveis
- [ ] Gráficos de gastos
- [ ] Multi-idioma (i18n)

## 📝 Notas de Release

### v1.1.1 (Atual)
- 🔧 Correção de 4 bugs críticos identificados em auditoria de código
- 🛡️ Proteção de índice em acesso a listas
- 🛡️ Parsing seguro de valores numéricos (double.tryParse)
- 🛡️ Correção de condição de corrida em navegação
- 🛡️ Proteção contra notifyListeners em widgets desmontados

### v1.1.0
- ✨ Filtro por período (Hoje, 7 dias, 30 dias, Tudo)
- ✨ Ordenação persistente (data, valor asc/desc)
- ✨ Percentual de despesas visíveis no card de totais
- ♿ Melhorias de acessibilidade

### v1.0.3
- ✨ Filtro por categoria de despesa
- ✨ Contagem de despesas no resumo

## 📜 Licença

MIT © [Paulo Filho](https://github.com/pdonizete) — Construído com 💚 e muita ☕

---

> **Nota:** Este projeto demonstra um processo moderno de desenvolvimento assistido por IA, onde um diretor técnico humano define visão, arquitetura e critérios de qualidade, enquanto agentes de IA executam implementação sob supervisão rigorosa.
