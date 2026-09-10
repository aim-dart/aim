/// Base class for environment types.
///
/// Users can extend this class to define their own type-safe context variables.
///
/// Example:
/// ```dart
/// class MyEnv extends Env {
///   String userId = '';
///   User? user;
///   Map<String, dynamic> metadata = {};
/// }
///
/// void main() {
///   final app = Aim<MyEnv>();
///
///   app.use((c, next) async {
///     c.variables.userId = '123';
///     c.variables.user = User(id: '123', name: 'Alice');
///     await next();
///   });
///
///   app.get('/profile', (c) async {
///     final userId = c.variables.userId;  // String型
///     final user = c.variables.user;      // User?型
///     return c.json({'userId': userId, 'name': user?.name});
///   });
/// }
/// ```
abstract class Env {}

/// Default empty environment.
///
/// This is used when no custom environment is specified.
class EmptyEnv extends Env {}
