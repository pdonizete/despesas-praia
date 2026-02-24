import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('audit documentation', () {
    final auditDoc = File('docs/progress/sinopse_api_key_audit.md');

    test('exists in docs/progress', () {
      expect(auditDoc.existsSync(), isTrue);
    });

    test('contains required checklist scope and explicit statuses', () {
      final content = auditDoc.readAsStringSync();

      expect(content, contains('Armazenamento seguro da API key'));
      expect(content, contains('Migração suave'));
      expect(content, contains('Workflow de build APK release'));
      expect(content, contains('release por tag'));
      expect(content, contains('Release notes'));

      expect(content, contains('**Implementado**'));
      expect(content, contains('**Faltante**'));

      expect(content, contains('Já estava implementado corretamente'));
      expect(content, contains('Exige complemento'));
    });
  });
}
