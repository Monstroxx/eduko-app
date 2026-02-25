// Stub — actual implementations are in native.dart and web.dart.
// This file exists for conditional imports.
export 'native.dart' if (dart.library.html) 'web.dart';
