# aim_database

Database abstraction layer for the Aim framework.

## Overview

`aim_database` provides common interfaces for database drivers in the Aim ecosystem. This package defines the `Database` and `Transaction` abstract classes that concrete database implementations (like `aim_postgres`) must implement.

## Installation

This package is typically used as a dependency of database driver packages. You generally don't need to install it directly.

If you need database functionality, use a concrete driver package:

- [aim_postgres](https://pub.dev/packages/aim_postgres) - PostgreSQL driver

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.