import 'package:shared_preferences/shared_preferences.dart';

/// A thin typed wrapper around [SharedPreferences] that tolerates being
/// touched before [init] completes.
///
/// The singleton is lazily self-initialising: if any call runs before
/// [init] resolves, it returns a safe fallback (null / false / empty)
/// instead of throwing a `LateInitializationError`. This is important
/// because multiple services grab a reference to `StorageService()` at
/// startup and can race the bootstrap sequence.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Eagerly initialise the underlying [SharedPreferences] instance.
  /// Call once at app startup (see `main.dart`). Safe to call again —
  /// subsequent calls are no-ops.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// True once [SharedPreferences] is available.
  bool get isReady => _prefs != null;

  // ─── Writes ────────────────────────────────────────────────────────────
  Future<bool> saveString(String key, String value) async {
    final prefs = await _ensureReady();
    return prefs.setString(key, value);
  }

  Future<bool> saveInt(String key, int value) async {
    final prefs = await _ensureReady();
    return prefs.setInt(key, value);
  }

  Future<bool> saveDouble(String key, double value) async {
    final prefs = await _ensureReady();
    return prefs.setDouble(key, value);
  }

  Future<bool> saveBool(String key, bool value) async {
    final prefs = await _ensureReady();
    return prefs.setBool(key, value);
  }

  Future<bool> saveStringList(String key, List<String> value) async {
    final prefs = await _ensureReady();
    return prefs.setStringList(key, value);
  }

  Future<bool> removeKey(String key) async {
    final prefs = await _ensureReady();
    return prefs.remove(key);
  }

  Future<bool> clear() async {
    final prefs = await _ensureReady();
    return prefs.clear();
  }

  // ─── Reads ─────────────────────────────────────────────────────────────
  // These are sync on purpose — callers already stored the value, they
  // just want to read it back. If prefs isn't ready we return null/false
  // rather than throwing; startup callers treat that as "no cached value"
  // and carry on.
  String? getString(String key) => _prefs?.getString(key);

  int? getInt(String key) => _prefs?.getInt(key);

  double? getDouble(String key) => _prefs?.getDouble(key);

  bool? getBool(String key) => _prefs?.getBool(key);

  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  bool hasKey(String key) => _prefs?.containsKey(key) ?? false;

  Set<String> getKeys() => _prefs?.getKeys() ?? const {};

  /// Awaits initialisation for write operations.
  Future<SharedPreferences> _ensureReady() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
