/// Parsed form data from application/x-www-form-urlencoded.
///
/// Provides type-safe access to form fields with support for
/// default values and key existence checks.
///
/// Example:
/// ```dart
/// final form = FormData({'username': 'alice', 'age': '30'});
/// print(form['username']);  // 'alice'
/// print(form['email']);     // null
/// print(form.get('email', 'default@example.com')); // 'default@example.com'
/// ```
class FormData {
  /// The parsed form data.
  final Map<String, String> _data;

  /// Creates a [FormData] instance with the given data.
  ///
  /// The data is made immutable to ensure thread-safety and prevent
  /// accidental modifications.
  FormData(Map<String, String> data) : _data = Map.unmodifiable(data);

  /// Gets the value for the given [key].
  ///
  /// Returns `null` if the key doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final username = form['username']; // String?
  /// ```
  String? operator [](String key) => _data[key];

  /// Gets the value for the given [key] with an optional [defaultValue].
  ///
  /// Returns the value if it exists, otherwise returns [defaultValue].
  ///
  /// Example:
  /// ```dart
  /// final remember = form.get('remember', 'false'); // String?
  /// ```
  String? get(String key, [String? defaultValue]) =>
      _data[key] ?? defaultValue;

  /// Checks if the form data contains the given [key].
  ///
  /// Example:
  /// ```dart
  /// if (form.has('email')) {
  ///   print('Email provided');
  /// }
  /// ```
  bool has(String key) => _data.containsKey(key);

  /// Returns all keys in the form data.
  Iterable<String> get keys => _data.keys;

  /// Returns all values in the form data.
  Iterable<String> get values => _data.values;

  /// Returns all entries in the form data.
  Iterable<MapEntry<String, String>> get entries => _data.entries;

  /// Converts the form data to an unmodifiable [Map].
  ///
  /// Example:
  /// ```dart
  /// final map = form.toMap();
  /// print(map); // {username: alice, age: 30}
  /// ```
  Map<String, String> toMap() => Map.unmodifiable(_data);

  @override
  String toString() => 'FormData($_data)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FormData) return false;
    if (_data.length != other._data.length) return false;
    for (final key in _data.keys) {
      if (_data[key] != other._data[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_data.entries);
}
