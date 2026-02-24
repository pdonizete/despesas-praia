# Auditoria de Implementação — API key segura + pipeline de release

Data: 2026-02-24
Branch auditada: `feat/acessibilidade-screenreader-mvp`

## Objetivo
Auditar o estado atual do repositório para evitar retrabalho e listar apenas complementos necessários para o escopo: armazenamento seguro da API key, migração suave, testes, build/release por tag com anexo de APK e release notes.

## Checklist de status (com evidências)

| Item | Status | Evidências (arquivo:linha) | Complemento necessário |
|---|---|---|---|
| Armazenamento seguro da API key com `flutter_secure_storage` | **Implementado** | Dependência presente em `pubspec.yaml:19`; wrapper seguro e store em `lib/api_key_store.dart:1-55`; chave padrão `api_key` em `lib/api_key_store.dart:40` | Integrar `SecureApiKeyStore` ao fluxo funcional da feature que consome API key (não há uso em `lib/main.dart`) |
| Migração suave de armazenamento legado → seguro | **Faltante** | Não foi identificada rotina de migração (ex.: leitura de chave legada + escrita no secure storage + limpeza) em `lib/` (apenas CRUD seguro em `lib/api_key_store.dart:45-54`) | Implementar serviço/fluxo de migração idempotente e testes cobrindo cenários com e sem valor legado |
| Testes de API key/secure storage | **Implementado** | Casos de escrita/leitura, remoção e chave customizada em `test/api_key_store_test.dart:23-56` | Adicionar testes de migração quando o item acima for implementado |
| Workflow de build APK release | **Implementado** | Build release APK em `.github/workflows/release.yml:27-28` | Sem complemento obrigatório no escopo desta auditoria |
| Workflow de release por tag com anexo `app-release.apk` | **Implementado** | Trigger por tag `v*.*.*` em `.github/workflows/release.yml:3-6`; upload do arquivo em `.github/workflows/release.yml:34` | Sem complemento obrigatório no escopo desta auditoria |
| Release notes automáticas | **Implementado** | `generate_release_notes: true` em `.github/workflows/release.yml:33` | Opcional: adicionar template/manual de notas se o time quiser padronização adicional |
| CI com validação de tipo/lint e testes | **Implementado** | `flutter analyze` em `.github/workflows/ci.yml:18-20`; `flutter test` em `.github/workflows/ci.yml:24-26` | Sem complemento obrigatório no escopo desta auditoria |

## Resumo objetivo

### Já estava implementado corretamente
- Camada de armazenamento seguro da API key (`flutter_secure_storage`) com abstração testável.
- Testes unitários básicos para operações da API key.
- Pipeline de release por tag com build de APK e anexo de `app-release.apk`.
- Geração automática de release notes no release workflow.
- CI com análise estática e testes.

### Exige complemento
- **Migração suave** do armazenamento legado para o seguro (não encontrada).
- **Integração funcional** do `SecureApiKeyStore` no fluxo que efetivamente usa API key (a camada existe, mas não há consumo visível no app atual).

## Recomendação de próximos passos (sem retrabalho)
1. Implementar apenas a migração idempotente (legado → secure storage) e cobrir com testes.
2. Conectar `SecureApiKeyStore` ao ponto de uso real da API key (sem refatorar o que já está correto).
3. Manter workflows atuais, apenas ajustar se surgirem requisitos adicionais de distribuição.
