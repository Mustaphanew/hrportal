import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Language preference mode.
///
/// - [system] → follow device language (AR/EN) with EN fallback
/// - [en] → force English
/// - [ar] → force Arabic
enum AppLocaleMode {
  system,
  en,
  ar,
}

FlutterSecureStorage _createStorage() {
  return kIsWeb ? const FlutterSecureStorage() : const FlutterSecureStorage();
}

AppLocaleMode _modeFromString(String? v) {
  switch ((v ?? '').toLowerCase()) {
    case 'ar':
      return AppLocaleMode.ar;
    case 'en':
      return AppLocaleMode.en;
    case 'system':
    default:
      return AppLocaleMode.system;
  }
}

String _modeToString(AppLocaleMode mode) {
  switch (mode) {
    case AppLocaleMode.en:
      return 'en';
    case AppLocaleMode.ar:
      return 'ar';
    case AppLocaleMode.system:
    default:
      return 'system';
  }
}

Locale _deviceLocaleOrEnglish() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final locales = dispatcher.locales;
  final device = locales.isNotEmpty ? locales.first : dispatcher.locale;

  final lang = device.languageCode.toLowerCase();
  if (lang == 'ar') return const Locale('ar');
  return const Locale('en');
}

Locale _resolveLocale(AppLocaleMode mode) {
  switch (mode) {
    case AppLocaleMode.ar:
      return const Locale('ar');
    case AppLocaleMode.en:
      return const Locale('en');
    case AppLocaleMode.system:
    default:
      return _deviceLocaleOrEnglish();
  }
}

Locale? _materialLocale(AppLocaleMode mode) {
  // When following system, return null so Flutter uses device locale.
  // Fallback behavior is controlled by supportedLocales ordering.
  if (mode == AppLocaleMode.system) return null;
  return _resolveLocale(mode);
}

/// Provides the app locale mode that should be used as the **initial** mode.
///
/// By default it follows the device language (System).
///
/// ✅ This provider is overridden in `main.dart` with a persisted value
/// if the user selected a language previously.
final initialLocaleModeProvider = Provider<AppLocaleMode>((_) {
  return AppLocaleMode.system;
});

/// Loads the saved locale mode from secure storage.
///
/// Returns `null` if no saved preference exists.
Future<AppLocaleMode?> loadSavedLocaleMode() async {
  final storage = _createStorage();
  final v = await storage.read(key: StorageKeys.locale);
  if (v == null || v.isEmpty) return null;
  return _modeFromString(v);
}

/// Computes the startup locale mode:
/// - if a saved preference exists → use it
/// - otherwise → follow system (device language)
Future<AppLocaleMode> loadStartupLocaleMode() async {
  final saved = await loadSavedLocaleMode();
  return saved ?? AppLocaleMode.system;
}

/// Locale mode controller.
///
/// - Reads the initial mode from [initialLocaleModeProvider]
/// - Allows changing language from inside the app (System/EN/AR)
/// - Persists user's choice using `flutter_secure_storage`
class LocaleModeController extends StateNotifier<AppLocaleMode> {
  final Ref _ref;
  final FlutterSecureStorage _storage;

  LocaleModeController(this._ref)
      : _storage = _createStorage(),
        super(_ref.read(initialLocaleModeProvider));

  Future<void> setMode(AppLocaleMode mode) async {
    if (state == mode) return;
    state = mode;
    await _storage.write(
      key: StorageKeys.locale,
      value: _modeToString(mode),
    );
  }

  Future<void> setModeString(String v) async {
    await setMode(_modeFromString(v));
  }

  Future<void> useSystemLanguage() async {
    await setMode(AppLocaleMode.system);
  }
}

/// The currently selected language mode (System/EN/AR).
final localeModeProvider =
    StateNotifierProvider<LocaleModeController, AppLocaleMode>(
  (ref) => LocaleModeController(ref),
);

/// The **resolved** locale that should be used for translations and formatting.
///
/// Note: when the mode is System, the resolved locale uses the device language
/// (AR/EN) with EN fallback.
final resolvedLocaleProvider = Provider<Locale>((ref) {
  final mode = ref.watch(localeModeProvider);
  return _resolveLocale(mode);
});

/// The locale value that should be passed to [MaterialApp.locale].
///
/// - System → `null` (let Flutter follow the device)
/// - EN/AR → forced locale
final materialLocaleProvider = Provider<Locale?>((ref) {
  final mode = ref.watch(localeModeProvider);
  return _materialLocale(mode);
});
