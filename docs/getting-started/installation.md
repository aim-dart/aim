# Installation

Get Aim installed and set up your development environment.

## Prerequisites

- [Dart SDK](https://dart.dev/get-dart) 3.10.0 or higher
- A code editor (VS Code, IntelliJ IDEA, etc.)

## Using Aim CLI (Recommended)

The easiest way to start a new project is using the Aim CLI:

```bash
# Install the Aim CLI
dart install aim_cli

# Create a new project
aim create my_app

# Navigate to the project
cd my_app

# Start the development server
aim dev
```

The CLI will:
- Create a new Dart project with the correct structure
- Install dependencies
- Set up a basic application
- Start the development server with hot reload

## Manual Setup

If you prefer to set up manually:

1. Create a new Dart project:

```bash
dart create my_app
cd my_app
```

2. Add Aim to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6

dev_dependencies:
  lints: ^5.0.0
```

3. Install dependencies:

```bash
dart pub get
```

## Next Steps

Now that you have Aim installed, head over to the [Quick Start](/getting-started/quick-start) guide to build your first application.
