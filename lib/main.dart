import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const Center(child: Text('Despesas (em construção)')),
      const Center(child: Text('Resumo / Acerto (em construção)')),
      SettingsPage(
        people: widget.storage.people,
        onSave: (names) {
          widget.storage.savePeople(names);
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Despesas da Praia')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Despesas'),
          NavigationDestination(icon: Icon(Icons.balance), label: 'Resumo'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.people, required this.onSave});

  final List<String> people;
  final ValueChanged<List<String>> onSave;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.people.map((name) => TextEditingController(text: name)).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Pessoas (fixas, editáveis)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _controllers[i],
              decoration: InputDecoration(labelText: 'Pessoa ${i + 1}', border: const OutlineInputBorder()),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            final names = _controllers
                .map((c) => c.text.trim().isEmpty ? 'Pessoa' : c.text.trim())
                .toList(growable: false);
            widget.onSave(names);
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

  void savePeople(List<String> names) {
    _box.put(_peopleKey, names.take(4).toList(growable: false));
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
