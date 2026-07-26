class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ApiCache {
  static final ApiCache _instance = ApiCache._();
  factory ApiCache() => _instance;
  ApiCache._();

  final Map<String, _CacheEntry> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void set<T>(String key, T data, {Duration ttl = const Duration(minutes: 5)}) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys.where((k) => k.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  void invalidateAll() {
    _cache.clear();
  }
}
