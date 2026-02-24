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
  ExpenseSortOption _selectedSort = ExpenseSortOption.dateRecentFirst;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.state.storage.loadExpenseSortOption();
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = categoriesInExpenses(widget.state.expenses);
    if (_selectedCategory != null &&
        !availableCategories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    final allExpenses = sortExpenses(
      widget.state.expenses,
      option: ExpenseSortOption.dateRecentFirst,
    );
    final filteredExpenses = applyExpenseCategoryFilter(
      allExpenses,
      _selectedCategory,
    );
    final expenses = sortExpenses(filteredExpenses, option: _selectedSort);

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
              _selectedCategory == null
                  ? 'Mostrando ${expenses.length} despesas.'
                  : 'Filtro ativo: ${_selectedCategory!.label} • ${expenses.length} de ${allExpenses.length} despesas.',
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
                    return Dismissible(
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
                          '${widget.state.people[e.paidBy]} • ${_dateFmt.format(e.date)}${e.description.isNotEmpty ? ' • ${e.description}' : ''}',
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total geral: ${_currency.format(state.totalGeral)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Cota por pessoa (total/4): ${_currency.format(quota)}'),
                const SizedBox(height: 8),
                for (var i = 0; i < state.people.length; i++)
                  ListTile(
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              final path = await state.exportarPdf();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('PDF salvo em: $path')));
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF e compartilhar'),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Quem deve para quem',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (transacoes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('Tudo acertado no momento. 🎉'),
            ),
          )
        else
          ...transacoes.map(
            (t) => Card(
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text('${state.people[t.from]} → ${state.people[t.to]}'),
                trailing: Text(
                  _currency.format(t.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pessoas (fixas, editáveis)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _controllers[i],
              decoration: InputDecoration(
                labelText: 'Pessoa ${i + 1}',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: () {
            final names = _controllers
                .map((c) => c.text.trim().isEmpty ? 'Pessoa' : c.text.trim())
                .toList(growable: false);
            widget.state.updatePeople(names);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nomes atualizados com sucesso.')),
            );
          },
          icon: const Icon(Icons.save),
          label: const Text('Salvar nomes'),
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
    final totals = List<double>.filled(4, 0);
    for (final e in expenses) {
      totals[e.paidBy] += e.value;
    }
    return totals;
  }

  double get quotaPorPessoa => totalGeral / 4;

  List<double> get saldos => calculateBalances(totalPorPessoa, peopleCount: 4);

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
    expenses = storage.expenses.map(Expense.fromMap).toList();
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
    people = names.take(4).toList(growable: false);
    await storage.savePeople(people);
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
              TextFormField(
                controller: _valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = double.tryParse((value ?? '').replaceAll(',', '.'));
                  if (v == null || v <= 0) {
                    return 'Informe um valor maior que 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _parcelasCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Parcelas',
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
              const SizedBox(height: 10),
              DropdownButtonFormField<Category>(
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
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
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
              const SizedBox(height: 10),
              ListTile(
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
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
            ],
          ),
        ),
      ),
    );
  }
}

enum Category { alimentacao, mercado, transporte, passeio, outros }

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

List<Category> categoriesInExpenses(Iterable<Expense> expenses) {
  final used = expenses.map((e) => e.category).toSet();
  return Category.values.where(used.contains).toList(growable: false);
}

List<Expense> applyExpenseCategoryFilter(
  List<Expense> expenses,
  Category? category,
) {
  if (category == null) return expenses;
  return expenses.where((e) => e.category == category).toList(growable: false);
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
      final names = raw.map((e) => e.toString()).toList();
      if (names.length == 4) return names;
    }
    final defaults = ['Pessoa 1', 'Pessoa 2', 'Pessoa 3', 'Pessoa 4'];
    _box.put(_peopleKey, defaults);
    return defaults;
  }

  Future<void> savePeople(List<String> names) async {
    await _box.put(_peopleKey, names.take(4).toList(growable: false));
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
