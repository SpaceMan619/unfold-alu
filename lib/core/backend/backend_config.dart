enum BackendMode { demo, firebase }

abstract final class BackendConfig {
  static const mode = BackendMode.firebase;

  static bool get usesFirebase => mode == BackendMode.firebase;
}
