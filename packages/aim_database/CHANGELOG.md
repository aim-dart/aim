## 0.0.1

- Initial release of `aim_database` package
- Added `Database` abstract class with `query()`, `execute()`, `transaction()`, and `close()` methods
- Added `Transaction` abstract class with `query()` and `execute()` methods
- Support for named parameters (`:name`) and positional arguments (`$1`)