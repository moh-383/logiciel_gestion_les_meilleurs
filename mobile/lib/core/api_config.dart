/// À remplacer à l'exécution avec --dart-define=API_BASE_URL=...
/// Android emulator : http://10.0.2.2:8000/api/v1.
/// Desktop : http://127.0.0.1:8000/api/v1.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);
