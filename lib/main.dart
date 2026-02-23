import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final expenses = [...state.expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

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
                    'Total geral: ${_currency.format(state.totalGeral)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < state.people.length; i++)
                    Text(
                      '${state.people[i]}: ${_currency.format(state.totalPorPessoa[i])}',
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: expenses.isEmpty
              ? const Center(child: Text('Nenhuma despesa cadastrada ainda.'))
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
                      onDismissed: (_) => state.deleteExpense(e.id),
                      child: ListTile(
                        title: Text(
                          '${_currency.format(e.value)} • ${e.category.label}',
                        ),
                        subtitle: Text(
                          '${state.people[e.paidBy]} • ${_dateFmt.format(e.date)}${e.description.isNotEmpty ? ' • ${e.description}' : ''}',
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

  List<double> get saldos {
    final paid = totalPorPessoa;
    final quota = quotaPorPessoa;
    return paid.map((p) => p - quota).toList(growable: false);
  }

  List<SettlementTransaction> calcularAcertos() {
    final list = <SettlementTransaction>[];
    final deb = <(int, double)>[];
    final cred = <(int, double)>[];

    for (var i = 0; i < saldos.length; i++) {
      final value = saldos[i];
      if (value < -0.009) deb.add((i, -value));
      if (value > 0.009) cred.add((i, value));
    }

    var d = 0;
    var c = 0;
    while (d < deb.length && c < cred.length) {
      final (debIdx, debVal) = deb[d];
      final (credIdx, credVal) = cred[c];
      final amount = debVal < credVal ? debVal : credVal;
      list.add(
        SettlementTransaction(from: debIdx, to: credIdx, amount: amount),
      );

      final newDeb = debVal - amount;
      final newCred = credVal - amount;
      deb[d] = (debIdx, newDeb);
      cred[c] = (credIdx, newCred);

      if (newDeb <= 0.009) d++;
      if (newCred <= 0.009) c++;
    }
    return list;
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
    String description = '',
  }) async {
    final item = Expense(
      id: _uuid.v4(),
      value: value,
      category: category,
      paidBy: paidBy,
      date: DateTime(date.year, date.month, date.day),
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
  final _descriptionCtrl = TextEditingController();

  Category _category = Category.alimentacao;
  int _paidBy = 0;
  DateTime _date = DateTime.now();

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
                    await widget.state.addExpense(
                      value: value,
                      category: _category,
                      paidBy: _paidBy,
                      date: _date,
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

class SettlementTransaction {
  SettlementTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });

  final int from;
  final int to;
  final double amount;
}

class Expense {
  Expense({
    required this.id,
    required this.value,
    required this.category,
    required this.paidBy,
    required this.date,
    required this.description,
  });

  final String id;
  final double value;
  final Category category;
  final int paidBy;
  final DateTime date;
  final String description;

  Map<String, dynamic> toMap() => {
    'id': id,
    'value': value,
    'category': category.name,
    'paidBy': paidBy,
    'date': date.toIso8601String(),
    'description': description,
  };

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      value: (map['value'] as num).toDouble(),
      category: Category.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => Category.outros,
      ),
      paidBy: map['paidBy'] as int,
      date: DateTime.parse(map['date'] as String),
      description: (map['description'] as String?) ?? '',
    );
  }
}

class LocalStorage {
  LocalStorage(this._box);

  final Box _box;

  static const _peopleKey = 'people';
  static const _expensesKey = 'expenses';

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
}
