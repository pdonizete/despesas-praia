import 'package:despesas_praia/api_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureKeyValueStorage implements SecureKeyValueStorage {
  final Map<String, String> data = {};

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

void main() {
  group('SecureApiKeyStore', () {
    test('writes and reads API key using secure storage key', () async {
      final secureStorage = _FakeSecureKeyValueStorage();
      final store = SecureApiKeyStore(secureStorage: secureStorage);

      await store.writeApiKey('my-secret-key');
      final value = await store.readApiKey();

      expect(value, 'my-secret-key');
      expect(secureStorage.data, containsPair('api_key', 'my-secret-key'));
    });

    test('deletes API key from secure storage', () async {
      final secureStorage = _FakeSecureKeyValueStorage();
      final store = SecureApiKeyStore(secureStorage: secureStorage);

      await store.writeApiKey('my-secret-key');
      await store.deleteApiKey();

      expect(await store.readApiKey(), isNull);
      expect(secureStorage.data.containsKey('api_key'), isFalse);
    });

    test('supports custom storage key', () async {
      final secureStorage = _FakeSecureKeyValueStorage();
      final store = SecureApiKeyStore(
        secureStorage: secureStorage,
        storageKey: 'custom_api_key',
      );

      await store.writeApiKey('custom-value');

      expect(secureStorage.data, containsPair('custom_api_key', 'custom-value'));
      expect(secureStorage.data.containsKey('api_key'), isFalse);
    });
  });
}
