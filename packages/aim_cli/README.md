# aim_cli

Command-line tools for the Aim web framework.

## Overview

`aim_cli` provides a set of command-line tools for creating and managing Aim framework projects. It includes project scaffolding, a development server with hot reload, and more.

## Features

- 🚀 **Project Scaffolding** - Quickly create new Aim projects with proper structure
- 🔥 **Hot Reload** - Automatic server restart when files change
- 📦 **Project Templates** - Pre-configured project structure with examples
- 🛠️ **Development Server** - Built-in development server with file watching
- ⚡ **Fast** - Optimized for quick iteration during development

## Installation

### From pub.dev (Recommended)

```bash
dart install aim_cli
```

After installation, the `aim` command will be available as a regular command in your terminal.

### Local Development

For local development, install the CLI from the local path:

```bash
# From the repository root
dart install packages/aim_cli

# Or from the package directory
cd packages/aim_cli
dart install .
```

After installation, you can use the `aim` command just like a regular command. The CLI will use the local source code, allowing you to test changes immediately.

## Commands

### `aim create`

Create a new Aim project.

#### Usage

```bash
aim create <project_name>
```

#### Example

```bash
aim create my_awesome_api
cd my_awesome_api
dart pub get
```

#### What it Creates

The `create` command scaffolds a new project with the following structure:

```
my_awesome_api/
├── bin/
│   └── server.dart          # Server entry point
├── lib/
│   └── src/
│       └── server.dart      # Application logic
├── test/
│   └── my_awesome_api_test.dart  # Test file
├── pubspec.yaml             # Dependencies
├── .gitignore
└── README.md
```

#### Project Name Requirements

- Must start with a lowercase letter
- Can only contain lowercase letters, numbers, and underscores
- Cannot use reserved words (dart, test, lib, bin)

### `aim dev`

Start the development server with hot reload support.

#### Usage

```bash
aim dev [options]
```

#### Options

- `-e, --entry <path>` - Server entry point (default: `bin/server.dart`)
- `--host <host>` - Server host (if configured in pubspec.yaml)
- `-p, --port <port>` - Server port (if configured in pubspec.yaml)
- `--[no-]hot-reload` - Enable/disable hot reload (default: enabled)
- `--watch <dirs>` - Comma-separated list of directories to watch (default: `lib,bin`)

#### Examples

```bash
# Start with default settings
aim dev

# Start without hot reload
aim dev --no-hot-reload

# Start with custom entry point
aim dev --entry bin/app.dart

# Watch additional directories
aim dev --watch lib,bin,config
```

#### Hot Reload

When hot reload is enabled (default), the development server will:

1. Watch specified directories for file changes
2. Detect changes to `.dart` files and `pubspec.yaml`
3. Automatically restart the server when changes are detected
4. Display restart time and status

The hot reload feature uses a debounce mechanism (500ms) to avoid excessive restarts when multiple files change rapidly.

#### Environment Variables

You can configure environment variables in your `pubspec.yaml`:

```yaml
aim:
  entry: bin/server.dart
  env:
    PORT: 8080
    API_KEY: ${API_KEY}                    # Read from system env
    DB_URL: ${DB_URL:localhost:5432}       # With default value
```

The CLI supports the following environment variable formats:

- `$VAR_NAME` - Simple variable expansion
- `${VAR_NAME}` - Variable with braces
- `${VAR_NAME:default}` - Variable with default value

## Project Structure

A typical Aim project created with `aim create` has the following structure:

### `bin/server.dart`

The entry point that starts the server:

```dart
import 'dart:io';
import 'package:my_project/src/server.dart';

void main() async {
  final app = createApp();

  final server = await app.serve(
    host: InternetAddress.anyIPv4,
    port: 8080,
  );

  print('🚀 Server started: http://${server.host}:${server.port}');
}
```

### `lib/src/server.dart`

Application logic with routes and middleware:

```dart
import 'package:aim_server/aim_server.dart';

Aim createApp() {
  final app = Aim();

  // Middleware
  app.use((c, next) async {
    print('[${DateTime.now()}] ${c.method} ${c.path}');
    await next();
  });

  // Routes
  app.get('/', (c) async {
    return c.json({'message': 'Hello, Aim!'});
  });

  return app;
}
```

### `test/`

Contains test files for your application:

```dart
import 'package:test/test.dart';

void main() {
  test('sample test', () {
    expect(true, isTrue);
  });
}
```

## Configuration

### pubspec.yaml

Configure Aim-specific settings in your `pubspec.yaml`:

```yaml
name: my_project
description: My Aim web server

dependencies:
  aim_server:
    git:
      url: https://github.com/aim-dart/aim.git
      path: packages/aim_server

aim:
  entry: bin/server.dart  # Entry point (optional)
  env:                    # Environment variables (optional)
    PORT: 8080
    HOST: localhost
```

## Development Workflow

1. **Create a new project**
   ```bash
   aim create my_api
   cd my_api
   ```

2. **Install dependencies**
   ```bash
   dart pub get
   ```

3. **Start development server**
   ```bash
   aim dev
   ```

4. **Make changes to your code**
   - Edit files in `lib/` or `bin/`
   - Server automatically restarts on save

5. **Run tests**
   ```bash
   dart test
   ```

6. **Build for production**
   ```bash
   dart compile exe bin/server.dart -o server
   ./server
   ```

## Troubleshooting

### Command not found

If the `aim` command is not found after installation, ensure that Dart's bin directory is in your PATH:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

Add this to your shell configuration file (`.bashrc`, `.zshrc`, etc.) to make it permanent.

> **Note:** With Dart 3.10+, the `dart install` command automatically handles PATH configuration in most cases.

### Hot reload not working

- Ensure you're running the server from the project root directory where `pubspec.yaml` exists
- Check that the watch directories contain `.dart` files
- Try restarting the development server

### Entry point not found

Make sure the entry point file exists and is specified correctly:

- Default: `bin/server.dart`
- Or specify in `pubspec.yaml` under `aim.entry`
- Or use the `--entry` flag

## Examples

See the [examples](../../examples) directory in the main repository for complete working examples.

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
