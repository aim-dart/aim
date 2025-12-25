/// Form data parsing for Aim framework.
///
/// Provides support for parsing `application/x-www-form-urlencoded` form data
/// in Aim server applications.
///
/// ## Usage
///
/// Import this package along with `aim_server`:
///
/// ```dart
/// import 'package:aim_server/aim_server.dart';
/// import 'package:aim_form/aim_server_form.dart';
/// ```
///
/// Then use the `formData()` extension method on requests:
///
/// ```dart
/// app.post('/login', (c) async {
///   final form = await c.req.formData();
///   final username = form['username'];
///   final password = form['password'];
///   return c.json({'user': username});
/// });
/// ```
library;

export 'src/form_data.dart';
export 'src/form_request.dart';
