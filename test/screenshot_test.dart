import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:despesas_praia/main.dart';

// Mock storage para testes - não depende de Hive
class MockStorage implements LocalStorage {
  final List<String> _people = ['João', 'Maria', 'Pedro'];
  final List<Map<String, dynamic>> _expenses = [];
  ExpenseSortOption _sortOption = ExpenseSortOption.dateRecentFirst;

  MockStorage() {
    // Criar despesas de exemplo
    final now = DateTime(2024, 1, 15); // Data fixa para consistência
    _expenses.addAll([
      {
        'id': '1',
        'value': 150.0,
        'category': 'alimentacao',
        'paidBy': 0, // João
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'description': 'Almoço na praia',
        'parcelas': 1,
      },
      {
        'id': '2',
        'value': 89.5,
        'category': 'transporte',
        'paidBy': 1, // Maria
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'description': 'Uber',
        'parcelas': 1,
      },
      {
        'id': '3',
        'value': 245.0,
        'category': 'mercado',
        'paidBy': 2, // Pedro
        'date': now.toIso8601String(),
        'description': 'Compras do mercado',
        'parcelas': 1,
      },
      {
        'id': '4',
        'value': 120.0,
        'category': 'passeio',
        'paidBy': 0, // João
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'description': 'Passeio de barco',
        'parcelas': 1,
      },
    ]);
  }

  @override
  List<String> get people => _people;

  @override
  Future<void> savePeople(List<String> names) async {}

  @override
  List<Map<String, dynamic>> get expenses => _expenses;

  @override
  Future<void> saveExpenses(List<Map<String, dynamic>> list) async {}

  @override
  ExpenseSortOption loadExpenseSortOption() => _sortOption;

  @override
  Future<void> saveExpenseSortOption(String optionName) async {}
}

// Widget wrapper para evitar inicialização do Hive
class TestApp extends StatelessWidget {
  final LocalStorage storage;
  final Widget home;

  const TestApp({super.key, required this.storage, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despesas da Praia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}

void main() {
  setUpAll(() async {
    // Inicializar Hive com diretório temporário para testes
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    
    // Abrir box necessária para o app
    await Hive.openBox('despesas_praia');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Screenshots', () {
    testWidgets('Tela Home - Lista de Despesas', (WidgetTester tester) async {
      final storage = MockStorage();
      
      await tester.pumpWidget(
        TestApp(storage: storage, home: HomePage(storage: storage)),
      );
      
      // Aguardar carregamento
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Capturar screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('test/screenshots/01_home.png'),
      );
    });

    testWidgets('Tela Resumo - Acerto', (WidgetTester tester) async {
      final storage = MockStorage();
      
      await tester.pumpWidget(
        TestApp(storage: storage, home: HomePage(storage: storage)),
      );
      
      // Aguardar carregamento
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Clicar na aba Resumo
      final resumoButton = find.text('Resumo');
      expect(resumoButton, findsOneWidget);
      await tester.tap(resumoButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Capturar screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('test/screenshots/02_resumo.png'),
      );
    });

    testWidgets('Tela Configuracoes', (WidgetTester tester) async {
      final storage = MockStorage();
      
      await tester.pumpWidget(
        TestApp(storage: storage, home: HomePage(storage: storage)),
      );
      
      // Aguardar carregamento
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Clicar na aba Config
      final configButton = find.text('Config');
      expect(configButton, findsOneWidget);
      await tester.tap(configButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Capturar screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('test/screenshots/03_config.png'),
      );
    });
  });
}
