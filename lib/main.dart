import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'domain/settlement.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFmt = DateFormat('dd/MM/yyyy');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeDateFormatting('pt_BR', null);
  final box = await Hive.openBox('despesas_praia');
  runApp(DespesasDaPraiaApp(storage: LocalStorage(box)));
}

class DespesasDaPraiaApp extends StatelessWidget {
  const DespesasDaPraiaApp({super.key, required this.storage});

  final LocalStorage storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despesas da Praia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: HomePage(storage: storage),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.storage});

  final LocalStorage storage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppState _state;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _state = AppState(widget.storage)..load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExpensesPage(state: _state),
      SettlementPage(state: _state),
      SettingsPage(state: _state),
    ];

    return AnimatedBuilder(
      animation: _state,
      builder: (context, child) => Scaffold(
        appBar: AppBar(title: const Text('Despesas da Praia')),
        body: pages[_index],
        floatingActionButton: _index == 0
            ? FloatingActionButton.extended(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddExpenseSheet(state: _state),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar despesa'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long),
              label: 'Despesas',
            ),
            NavigationDestination(icon: Icon(Icons.balance), label: 'Resumo'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
          ],
        ),
      ),
    );
  }
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key, required this.state});

  final AppState state;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  Category? _selectedCategory;
  int? _selectedPaidBy;
  ExpensePeriodFilter _selectedPeriod = ExpensePeriodFilter.all;
  ExpenseSortOption _selectedSort = ExpenseSortOption.dateRecentFirst;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.state.storage.loadExpenseSortOption();
  }

  String _buildFilterStatusText({
    required int totalExpenses,
    required int periodFilteredCount,
    required String paidByLabel,
  }) {
    final periodLabel = _selectedPeriod == ExpensePeriodFilter.all
        ? 'Tudo'
        : _selectedPeriod.label;
    final categoryLabel = _selectedCategory?.label ?? 'Todas';

    return 'Filtros ativos: período $periodLabel • categoria $categoryLabel • pagador $paidByLabel • total geral $totalExpenses despesas (após período: $periodFilteredCount).';
  }

  @override
  Widget build(BuildContext context) {
    final periodFilteredExpenses = applyExpensePeriodFilter(
      widget.state.expenses,
      _selectedPeriod,
    );
    final availableCategories = categoriesInExpenses(periodFilteredExpenses);
    if (_selectedCategory != null &&
        !availableCategories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    _selectedPaidBy = normalizeSelectedPaidBy(
      _selectedPaidBy,
      peopleCount: widget.state.people.length,
    );

    final categoryFilteredExpenses = applyExpenseCategoryFilter(
      periodFilteredExpenses,
      _selectedCategory,
    );
    final paidByFilteredExpenses = applyExpensePaidByFilter(
      categoryFilteredExpenses,
      _selectedPaidBy,
    );
    final expenses = sortExpenses(
      paidByFilteredExpenses,
      option: _selectedSort,
    );
    final paidByLabel = _selectedPaidBy == null
        ? 'Todos'
        : widget.state.people[_selectedPaidBy!];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total geral: ${_currency.format(widget.state.totalGeral)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < widget.state.people.length; i++)
                    Text(
                      '${widget.state.people[i]}: ${_currency.format(widget.state.totalPorPessoa[i])}',
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Totais gerais (não aplicam filtro da lista).',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpensePeriodFilter.values
                  .map(
                    (period) => ChoiceChip(
                      label: Text(period.label),
                      selected: _selectedPeriod == period,
                      onSelected: (_) {
                        setState(() => _selectedPeriod = period);
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<Category?>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Filtrar por categoria',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<Category?>(
                value: null,
                child: Text('Todas'),
              ),
              ...availableCategories.map(
                (category) => DropdownMenuItem<Category?>(
                  value: category,
                  child: Text(category.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: DropdownButtonFormField<int?>(
            initialValue: _selectedPaidBy,
            decoration: const InputDecoration(
              labelText: 'Filtrar por pagador',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...List.generate(widget.state.people.length, (index) {
                return DropdownMenuItem<int?>(
                  value: index,
                  child: Text(widget.state.people[index]),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedPaidBy = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: DropdownButtonFormField<ExpenseSortOption>(
            initialValue: _selectedSort,
            decoration: const InputDecoration(
              labelText: 'Ordenar por',
              border: OutlineInputBorder(),
            ),
            items: ExpenseSortOption.values
                .map(
                  (option) => DropdownMenuItem<ExpenseSortOption>(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedSort = value);
              widget.state.storage.saveExpenseSortOption(value.name);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mostrando ${expenses.length} de ${widget.state.expenses.length} despesas',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _buildFilterStatusText(
                totalExpenses: widget.state.expenses.length,
                periodFilteredCount: periodFilteredExpenses.length,
                paidByLabel: paidByLabel,
              ),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: expenses.isEmpty
              ? const Center(
                  child: Text('Nenhuma despesa para o filtro selecionado.'),
                )
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (_, i) {
                    final e = expenses[i];
                    final personName = widget.state.people[e.paidBy];
                    return Semantics(
                      container: true,
                      label: buildExpenseItemSemanticsLabel(
                        expense: e,
                        personName: personName,
                      ),
                      child: Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => widget.state.deleteExpense(e.id),
                        child: ListTile(
                          title: Text(
                            '${_currency.format(e.value)} • ${e.category.label}${e.isParcelada ? ' • ${e.parcelas}x de ${_currency.format(e.valorParcela)}' : ''}',
                          ),
                          subtitle: Text(
                            '$personName • ${_dateFmt.format(e.date)}${e.description.isNotEmpty ? ' • ${e.description}' : ''}',
                          ),
                          trailing: Semantics(
                            button: true,
                            label:
                                'Excluir despesa de ${_currency.format(e.value)} da categoria ${e.category.label}',
                            hint: 'Toque para excluir esta despesa.',
                            child: IconButton(
                              onPressed: () => widget.state.deleteExpense(e.id),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Excluir despesa',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class SettlementPage extends StatelessWidget {
  const SettlementPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final quota = state.quotaPorPessoa;
    final saldos = state.saldos;
    final transacoes = state.calcularAcertos();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Semantics(
          container: true,
          label:
              'Resumo de totais e saldos. Total geral ${_currency.format(state.totalGeral)}. Cota por pessoa ${_currency.format(quota)}.',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total geral: ${_currency.format(state.totalGeral)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Cota por pessoa (total/${state.people.length}): ${_currency.format(quota)}',
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < state.people.length; i++)
                    Semantics(
                      container: true,
                      label:
                          '${state.people[i]}. Pagou ${_currency.format(state.totalPorPessoa[i])}. Saldo ${(saldos[i] >= 0 ? 'positivo' : 'negativo')} de ${_currency.format(saldos[i].abs())}.',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(state.people[i]),
                        subtitle: Text(
                          'Pagou: ${_currency.format(state.totalPorPessoa[i])}',
                        ),
                        trailing: Text(
                          '${saldos[i] >= 0 ? '+' : ''}${_currency.format(saldos[i])}',
                          style: TextStyle(
                            color: saldos[i] >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: 'Exportar PDF e compartilhar resumo de despesas',
            hint: 'Toque para gerar o PDF e abrir o compartilhamento.',
            child: FilledButton.icon(
              onPressed: () async {
                final path = await state.exportarPdf();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF salvo em: $path')),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF e compartilhar'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          container: true,
          label: 'Bloco de transações de acerto entre pessoas.',
          child: const Text(
            'Quem deve para quem',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        if (transacoes.isEmpty)
          Semantics(
            container: true,
            label: 'Nenhuma transação pendente. Tudo acertado no momento.',
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Tudo acertado no momento. 🎉'),
              ),
            ),
          )
        else
          ...transacoes.map(
            (t) => Semantics(
              container: true,
              label:
                  '${state.people[t.from]} deve ${_currency.format(t.amount)} para ${state.people[t.to]}',
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(
                    '${state.people[t.from]} → ${state.people[t.to]}',
                  ),
                  trailing: Text(
                    _currency.format(t.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.state.people
        .map((name) => TextEditingController(text: name))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _normalizedName(String raw, int index) {
    final value = raw.trim();
    return value.isEmpty ? 'Pessoa ${index + 1}' : value;
  }

  Future<void> _removePerson(int index) async {
    if (widget.state.people.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('É necessário manter ao menos 1 pessoa.')),
      );
      return;
    }

    final hasExpenses = widget.state.expenses.any((e) => e.paidBy == index);
    int? target;

    if (hasExpenses) {
      target = await showDialog<int>(
        context: context,
        builder: (context) {
          int selected = index == 0 ? 1 : 0;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Reatribuir despesas'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.state.people[index]} possui despesas. Escolha para quem reatribuir antes de remover.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selected,
                    items: List.generate(widget.state.people.length, (i) {
                      if (i == index) return null;
                      return DropdownMenuItem(
                        value: i,
                        child: Text(widget.state.people[i]),
                      );
                    }).whereType<DropdownMenuItem<int>>().toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selected = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Reatribuir para',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Reatribuir e remover'),
                ),
              ],
            ),
          );
        },
      );
      if (target == null) return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await widget.state.removePerson(index, reassignExpensesTo: target);
    _controllers.removeAt(index).dispose();
    messenger.showSnackBar(
      const SnackBar(content: Text('Pessoa removida com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pessoas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    textField: true,
                    label: 'Nome da pessoa ${i + 1}',
                    hint: 'Edite o nome para identificar melhor os gastos.',
                    child: TextField(
                      controller: _controllers[i],
                      decoration: InputDecoration(
                        labelText: 'Pessoa ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label:
                      'Remover ${_normalizedName(_controllers[i].text, i)} da lista de pessoas',
                  hint:
                      'Toque para remover esta pessoa e reatribuir despesas se necessário.',
                  child: IconButton.filledTonal(
                    onPressed: () => _removePerson(i),
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Remover pessoa',
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Adicionar nova pessoa',
                hint: 'Toque para incluir mais um campo de nome.',
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _controllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Adicionar pessoa'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          button: true,
          label: 'Salvar nomes das pessoas',
          hint: 'Toque para aplicar as alterações dos nomes cadastrados.',
          child: FilledButton.icon(
            onPressed: () async {
              final names = List.generate(
                _controllers.length,
                (i) => _normalizedName(_controllers[i].text, i),
                growable: false,
              );
              final messenger = ScaffoldMessenger.of(context);
              await widget.state.updatePeople(names);
              messenger.showSnackBar(
                const SnackBar(content: Text('Nomes atualizados com sucesso.')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar nomes'),
          ),
        ),
      ],
    );
  }
}

class AppState extends ChangeNotifier {
  AppState(this.storage);

  final LocalStorage storage;
  final _uuid = const Uuid();

  List<String> people = [];
  List<Expense> expenses = [];

  double get totalGeral => expenses.fold(0, (sum, e) => sum + e.value);

  List<double> get totalPorPessoa {
    final count = people.isEmpty ? 1 : people.length;
    final totals = List<double>.filled(count, 0);
    for (final e in expenses) {
      if (e.paidBy >= 0 && e.paidBy < totals.length) {
        totals[e.paidBy] += e.value;
      }
    }
    return totals;
  }

  double get quotaPorPessoa =>
      totalGeral / (people.isEmpty ? 1 : people.length);

  List<double> get saldos => calculateBalances(
    totalPorPessoa,
    peopleCount: people.isEmpty ? 1 : people.length,
  );

  List<SettlementTransfer> calcularAcertos() {
    return calculateSettlements(saldos);
  }

  Future<String> exportarPdf() async {
    final doc = pw.Document();
    final ordered = [...expenses]..sort((a, b) => a.date.compareTo(b.date));

    final DateTime? minDate = ordered.isNotEmpty ? ordered.first.date : null;
    final DateTime? maxDate = ordered.isNotEmpty ? ordered.last.date : null;
    final acertos = calcularAcertos();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Despesas da Praia')),
          pw.Text(
            'Período: ${minDate == null ? '-' : _dateFmt.format(minDate)} a ${maxDate == null ? '-' : _dateFmt.format(maxDate)}',
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Lista de despesas',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...ordered.map(
            (e) => pw.Bullet(
              text:
                  '${_dateFmt.format(e.date)} • ${e.category.label} • ${people[e.paidBy]} • ${_currency.format(e.value)}${e.isParcelada ? ' • ${e.parcelas}x de ${_currency.format(e.valorParcela)}' : ''}${e.description.isEmpty ? '' : ' • ${e.description}'}',
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Totais',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Total geral: ${_currency.format(totalGeral)}'),
          ...List.generate(
            people.length,
            (i) => pw.Text(
              '${people[i]} pagou: ${_currency.format(totalPorPessoa[i])}',
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Resumo / Ajustes',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Cota por pessoa: ${_currency.format(quotaPorPessoa)}'),
          ...List.generate(
            people.length,
            (i) => pw.Text(
              '${people[i]} saldo: ${(saldos[i] >= 0 ? '+' : '')}${_currency.format(saldos[i])}',
            ),
          ),
          pw.SizedBox(height: 8),
          if (acertos.isEmpty)
            pw.Text('Tudo acertado no momento.')
          else
            ...acertos.map(
              (a) => pw.Text(
                '${people[a.from]} deve ${_currency.format(a.amount)} para ${people[a.to]}',
              ),
            ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${dir.path}/despesas_praia_$stamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await doc.save());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Resumo de despesas da praia'),
    );

    return path;
  }

  void load() {
    people = storage.people;
    expenses = storage.expenses
        .map(Expense.fromMap)
        .map(
          (e) => e.paidBy >= 0 && e.paidBy < people.length
              ? e
              : e.copyWith(paidBy: 0),
        )
        .toList(growable: true);
    notifyListeners();
  }

  Future<void> addExpense({
    required double value,
    required Category category,
    required int paidBy,
    required DateTime date,
    int parcelas = 1,
    String description = '',
  }) async {
    if (value <= 0) {
      throw ArgumentError.value(value, 'value', 'Deve ser maior que 0.');
    }
    if (parcelas < 1) {
      throw ArgumentError.value(parcelas, 'parcelas', 'Deve ser no mínimo 1.');
    }
    if (paidBy < 0 || paidBy >= people.length) {
      throw ArgumentError.value(paidBy, 'paidBy', 'Índice inválido.');
    }

    final item = Expense(
      id: _uuid.v4(),
      value: value,
      category: category,
      paidBy: paidBy,
      date: DateTime(date.year, date.month, date.day),
      parcelas: parcelas,
      description: description.trim(),
    );
    expenses.add(item);
    await storage.saveExpenses(expenses.map((e) => e.toMap()).toList());
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((e) => e.id == id);
    await storage.saveExpenses(expenses.map((e) => e.toMap()).toList());
    notifyListeners();
  }

  Future<void> updatePeople(List<String> names) async {
    final normalized = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    people = normalized.isEmpty ? const ['Pessoa 1'] : normalized;
    expenses = expenses
        .map(
          (e) => e.paidBy >= 0 && e.paidBy < people.length
              ? e
              : e.copyWith(paidBy: 0),
        )
        .toList(growable: true);
    await storage.savePeople(people);
    await storage.saveExpenses(expenses.map((e) => e.toMap()).toList());
    notifyListeners();
  }

  Future<void> removePerson(int index, {int? reassignExpensesTo}) async {
    if (people.length <= 1) {
      throw StateError('É necessário manter ao menos 1 pessoa.');
    }
    if (index < 0 || index >= people.length) {
      throw ArgumentError.value(index, 'index', 'Índice inválido.');
    }

    final hasExpenses = expenses.any((e) => e.paidBy == index);
    if (hasExpenses && reassignExpensesTo == null) {
      throw StateError(
        'Informe reassignExpensesTo para remover pessoa com despesas.',
      );
    }

    if (reassignExpensesTo != null &&
        (reassignExpensesTo < 0 ||
            reassignExpensesTo >= people.length ||
            reassignExpensesTo == index)) {
      throw ArgumentError.value(
        reassignExpensesTo,
        'reassignExpensesTo',
        'Índice de reatribuição inválido.',
      );
    }

    final updatedExpenses = expenses
        .map((e) {
          var newPaidBy = e.paidBy;
          if (e.paidBy == index) {
            newPaidBy = reassignExpensesTo!;
          }
          if (newPaidBy > index) {
            newPaidBy -= 1;
          }
          return e.copyWith(paidBy: newPaidBy);
        })
        .toList(growable: true);

    final updatedPeople = [...people]..removeAt(index);

    people = updatedPeople;
    expenses = updatedExpenses;

    await storage.savePeople(people);
    await storage.saveExpenses(expenses.map((e) => e.toMap()).toList());
    notifyListeners();
  }
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key, required this.state});

  final AppState state;

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueCtrl = TextEditingController();
  final _parcelasCtrl = TextEditingController(text: '1');
  final _descriptionCtrl = TextEditingController();

  Category _category = Category.alimentacao;
  int _paidBy = 0;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _valueCtrl.dispose();
    _parcelasCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adicionar despesa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Semantics(
                textField: true,
                label: 'Campo valor da despesa em reais',
                hint: 'Informe o valor total gasto.',
                child: TextFormField(
                  controller: _valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    hintText: 'Exemplo: 120,50',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final v = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (v == null || v <= 0) {
                      return 'Informe um valor maior que 0';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                textField: true,
                label: 'Campo quantidade de parcelas',
                hint: 'Informe o número de parcelas. Mínimo 1.',
                child: TextFormField(
                  controller: _parcelasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Parcelas',
                    hintText: 'Exemplo: 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parcelas = int.tryParse((value ?? '').trim());
                    if (parcelas == null || parcelas < 1) {
                      return 'Informe parcelas (mínimo 1)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                label: 'Selecionar categoria da despesa',
                hint: 'Escolha uma categoria como alimentação ou transporte.',
                child: DropdownButtonFormField<Category>(
                  initialValue: _category,
                  items: Category.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _category = v ?? Category.alimentacao),
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                label: 'Selecionar quem pagou a despesa',
                hint: 'Escolha a pessoa responsável pelo pagamento.',
                child: DropdownButtonFormField<int>(
                  initialValue: _paidBy,
                  items: List.generate(
                    widget.state.people.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(widget.state.people[i]),
                    ),
                  ),
                  onChanged: (v) => setState(() => _paidBy = v ?? 0),
                  decoration: const InputDecoration(
                    labelText: 'Quem pagou',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: 'Selecionar data da despesa',
                hint: 'Data atual selecionada: ${_dateFmt.format(_date)}.',
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  title: const Text('Data'),
                  subtitle: Text(_dateFmt.format(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                textField: true,
                label: 'Campo descrição da despesa opcional',
                hint: 'Adicione detalhes para facilitar identificação.',
                child: TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'Salvar despesa',
                  hint: 'Toque para confirmar o cadastro da despesa.',
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final value = double.parse(
                        _valueCtrl.text.replaceAll(',', '.'),
                      );
                      final parcelas = int.parse(_parcelasCtrl.text.trim());
                      await widget.state.addExpense(
                        value: value,
                        category: _category,
                        paidBy: _paidBy,
                        date: _date,
                        parcelas: parcelas,
                        description: _descriptionCtrl.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Salvar despesa'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum Category { alimentacao, mercado, transporte, passeio, outros }

String buildExpenseItemSemanticsLabel({
  required Expense expense,
  required String personName,
}) {
  final parts = <String>[
    'Despesa de ${_currency.format(expense.value)}',
    'categoria ${expense.category.label}',
    'paga por $personName',
    'em ${_dateFmt.format(expense.date)}',
  ];

  if (expense.isParcelada) {
    parts.add(
      'parcelada em ${expense.parcelas} vezes de ${_currency.format(expense.valorParcela)}',
    );
  }

  if (expense.description.isNotEmpty) {
    parts.add('descrição: ${expense.description}');
  }

  return parts.join(', ');
}

extension CategoryX on Category {
  String get label {
    switch (this) {
      case Category.alimentacao:
        return 'Alimentação';
      case Category.mercado:
        return 'Mercado';
      case Category.transporte:
        return 'Transporte';
      case Category.passeio:
        return 'Passeio';
      case Category.outros:
        return 'Outros';
    }
  }
}

enum ExpensePeriodFilter { today, last7Days, last30Days, all }

extension ExpensePeriodFilterX on ExpensePeriodFilter {
  String get label {
    switch (this) {
      case ExpensePeriodFilter.today:
        return 'Hoje';
      case ExpensePeriodFilter.last7Days:
        return '7 dias';
      case ExpensePeriodFilter.last30Days:
        return '30 dias';
      case ExpensePeriodFilter.all:
        return 'Tudo';
    }
  }

  int? get windowInDays {
    switch (this) {
      case ExpensePeriodFilter.today:
        return 1;
      case ExpensePeriodFilter.last7Days:
        return 7;
      case ExpensePeriodFilter.last30Days:
        return 30;
      case ExpensePeriodFilter.all:
        return null;
    }
  }
}

List<Category> categoriesInExpenses(Iterable<Expense> expenses) {
  final used = expenses.map((e) => e.category).toSet();
  return Category.values.where(used.contains).toList(growable: false);
}

List<Expense> applyExpensePeriodFilter(
  Iterable<Expense> expenses,
  ExpensePeriodFilter period, {
  DateTime? now,
}) {
  final days = period.windowInDays;
  if (days == null) {
    return expenses.toList(growable: false);
  }

  final today = now ?? DateTime.now();
  final end = DateTime(today.year, today.month, today.day);
  final start = end.subtract(Duration(days: days - 1));

  return expenses
      .where((e) {
        final expenseDay = DateTime(e.date.year, e.date.month, e.date.day);
        return !expenseDay.isBefore(start) && !expenseDay.isAfter(end);
      })
      .toList(growable: false);
}

List<Expense> applyExpenseCategoryFilter(
  List<Expense> expenses,
  Category? category,
) {
  if (category == null) return expenses;
  return expenses.where((e) => e.category == category).toList(growable: false);
}

List<Expense> applyExpensePaidByFilter(List<Expense> expenses, int? paidBy) {
  if (paidBy == null) return expenses;
  return expenses.where((e) => e.paidBy == paidBy).toList(growable: false);
}

int? normalizeSelectedPaidBy(int? selectedPaidBy, {required int peopleCount}) {
  if (selectedPaidBy == null) return null;
  if (selectedPaidBy < 0 || selectedPaidBy >= peopleCount) return null;
  return selectedPaidBy;
}

enum ExpenseSortOption { dateRecentFirst, valueHighToLow, valueLowToHigh }

extension ExpenseSortOptionX on ExpenseSortOption {
  String get label {
    switch (this) {
      case ExpenseSortOption.dateRecentFirst:
        return 'Data (recente→antiga)';
      case ExpenseSortOption.valueHighToLow:
        return 'Valor (maior→menor)';
      case ExpenseSortOption.valueLowToHigh:
        return 'Valor (menor→maior)';
    }
  }
}

List<Expense> sortExpenses(
  Iterable<Expense> expenses, {
  ExpenseSortOption option = ExpenseSortOption.dateRecentFirst,
}) {
  final sorted = expenses.toList();

  int compareByRecentDate(Expense a, Expense b) => b.date.compareTo(a.date);

  switch (option) {
    case ExpenseSortOption.dateRecentFirst:
      sorted.sort(compareByRecentDate);
      break;
    case ExpenseSortOption.valueHighToLow:
      sorted.sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        if (byValue != 0) return byValue;
        return compareByRecentDate(a, b);
      });
      break;
    case ExpenseSortOption.valueLowToHigh:
      sorted.sort((a, b) {
        final byValue = a.value.compareTo(b.value);
        if (byValue != 0) return byValue;
        return compareByRecentDate(a, b);
      });
      break;
  }

  return sorted;
}

class Expense {
  Expense({
    required this.id,
    required this.value,
    required this.category,
    required this.paidBy,
    required this.date,
    int parcelas = 1,
    required this.description,
  }) : parcelas = parcelas < 1 ? 1 : parcelas;

  final String id;
  final double value;
  final Category category;
  final int paidBy;
  final DateTime date;
  final int parcelas;
  final String description;

  bool get isParcelada => parcelas > 1;
  double get valorParcela => value / parcelas;

  Expense copyWith({int? paidBy}) {
    return Expense(
      id: id,
      value: value,
      category: category,
      paidBy: paidBy ?? this.paidBy,
      date: date,
      parcelas: parcelas,
      description: description,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'value': value,
    'category': category.name,
    'paidBy': paidBy,
    'date': date.toIso8601String(),
    'parcelas': parcelas,
    'description': description,
  };

  static Expense fromMap(Map<String, dynamic> map) {
    final rawParcelas = map['parcelas'];
    final parsedParcelas = switch (rawParcelas) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };

    return Expense(
      id: map['id'] as String,
      value: (map['value'] as num).toDouble(),
      category: Category.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => Category.outros,
      ),
      paidBy: map['paidBy'] as int,
      date: DateTime.parse(map['date'] as String),
      parcelas: (parsedParcelas ?? 1) < 1 ? 1 : (parsedParcelas ?? 1),
      description: (map['description'] as String?) ?? '',
    );
  }
}

class LocalStorage {
  LocalStorage(this._box);

  final Box _box;

  static const _peopleKey = 'people';
  static const _expensesKey = 'expenses';
  static const _expensesSortOptionKey = 'expenses_sort_option';

  List<String> get people {
    final raw = _box.get(_peopleKey);
    if (raw is List) {
      final names = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (names.isNotEmpty) return names;
    }
    final defaults = ['Pessoa 1', 'Pessoa 2', 'Pessoa 3', 'Pessoa 4'];
    _box.put(_peopleKey, defaults);
    return defaults;
  }

  Future<void> savePeople(List<String> names) async {
    final normalized = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    await _box.put(
      _peopleKey,
      normalized.isEmpty ? const ['Pessoa 1'] : normalized,
    );
  }

  List<Map<String, dynamic>> get expenses {
    final raw = _box.get(_expensesKey);
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> saveExpenses(List<Map<String, dynamic>> list) async {
    final serialized = list.map(jsonEncode).toList(growable: false);
    await _box.put(_expensesKey, serialized);
  }

  ExpenseSortOption loadExpenseSortOption() {
    final raw = _box.get(_expensesSortOptionKey);
    if (raw is String) {
      return ExpenseSortOption.values.firstWhere(
        (option) => option.name == raw,
        orElse: () => ExpenseSortOption.dateRecentFirst,
      );
    }
    return ExpenseSortOption.dateRecentFirst;
  }

  Future<void> saveExpenseSortOption(String optionName) async {
    await _box.put(_expensesSortOptionKey, optionName);
  }
}
