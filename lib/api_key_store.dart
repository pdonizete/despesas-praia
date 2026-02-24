import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class ApiKeyStore {
  Future<String?> readApiKey();
  Future<void> writeApiKey(String apiKey);
  Future<void> deleteApiKey();
}

abstract interface class SecureKeyValueStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStorage implements SecureKeyValueStorage {
  FlutterSecureKeyValueStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({
    SecureKeyValueStorage? secureStorage,
    String storageKey = _defaultApiKeyStorageKey,
  }) : _secureStorage = secureStorage ?? FlutterSecureKeyValueStorage(),
       _storageKey = storageKey;

  static const _defaultApiKeyStorageKey = 'api_key';

  final SecureKeyValueStorage _secureStorage;
  final String _storageKey;

  @override
  Future<String?> readApiKey() => _secureStorage.read(_storageKey);

  @override
  Future<void> writeApiKey(String apiKey) {
    return _secureStorage.write(_storageKey, apiKey);
  }

  @override
  Future<void> deleteApiKey() => _secureStorage.delete(_storageKey);
}
