/// Base class for per-request typed context variables.
///
/// Extend this class to define variables that middleware and handlers share
/// through [Context.variables]. A fresh instance is created for every request
/// by the `variablesFactory` passed to `Aim`.
///
/// This is the equivalent of Hono's `Variables`. Runtime bindings such as
/// Cloudflare Workers' `env` are a different concept and are exposed by the
/// runtime adapter (for example `c.env` in `aim_edge`).
///
/// Example:
/// ```dart
/// class MyVariables extends Variables {
///   String userId = '';
///   User? user;
/// }
///
/// void main() {
///   final app = Aim<MyVariables>(variablesFactory: () => MyVariables());
///
///   app.use((c, next) async {
///     c.variables.userId = '123';
///     await next();
///   });
///
///   app.get('/profile', (c) async {
///     return c.json({'userId': c.variables.userId});
///   });
/// }
/// ```
abstract class Variables {}

/// Default variables type used when no custom [Variables] is specified.
class EmptyVariables extends Variables {}

/// Former name of [Variables]. Will be removed in a future release.
@Deprecated('Use Variables')
typedef Env = Variables;

/// Former name of [EmptyVariables]. Will be removed in a future release.
@Deprecated('Use EmptyVariables')
typedef EmptyEnv = EmptyVariables;
