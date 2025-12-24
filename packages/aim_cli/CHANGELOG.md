## 0.0.1

Initial release of aim_cli - Command-line tools for the Aim web framework.

### Features

- Project Scaffolding:
  - `aim create` command to generate new Aim projects
  - Pre-configured project structure with best practices
  - Automatic generation of example routes and middleware
- Development Server:
  - `aim dev` command to start development server
  - Hot reload support with automatic server restart on file changes
  - Configurable entry point
  - Environment variable support from `pubspec.yaml`
- File Watching:
  - Monitors `.dart` files and `pubspec.yaml` for changes
  - Debounced file watching (500ms) to avoid excessive restarts
  - Configurable watch directories
- Process Management:
  - Graceful shutdown with SIGTERM
  - Force kill fallback with SIGKILL
  - Clean process lifecycle management
- Project Validation:
  - Project name validation (lowercase, alphanumeric, underscores)
  - Reserved word checking
  - Directory existence validation

### Supported

- Dart SDK: `^3.10.0`
- Platforms: All platforms supported by Dart (Linux, macOS, Windows)
- Installation: `dart install aim_cli` (Dart 3.10+)

### Commands

- `aim create <project_name>` - Create a new Aim project
- `aim dev [options]` - Start development server with hot reload

### What's Included

- Project templates for quick start
- Hot reload infrastructure
- File watching utilities
- Environment variable expansion
- Process management utilities
