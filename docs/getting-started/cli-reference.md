# CLI Reference

Complete guide to the Aim CLI tool.

## Installation

```bash
dart install aim_cli
```

## Commands

### `aim create`

Create a new Aim framework project.

**Usage:**
```bash
aim create <project_name>
```

**Example:**
```bash
aim create my_app
cd my_app
```

This command:
- Creates a new directory with the project name
- Generates project structure (bin/, lib/, test/)
- Creates `pubspec.yaml` with Aim dependencies
- Generates a basic server in `bin/server.dart`
- Runs `dart pub get` to install dependencies

### `aim dev`

Start the development server with hot reload support.

**Usage:**
```bash
aim dev [options]
```

**Options:**

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--entry` | `-e` | Server entry point | `bin/server.dart` |
| `--host` | | Server host | From pubspec.yaml |
| `--port` | `-p` | Server port | From pubspec.yaml |
| `--hot-reload` | | Enable hot reload | `true` |
| `--no-hot-reload` | | Disable hot reload | |
| `--watch` | | Directories to watch (comma-separated) | `lib,bin` |

**Examples:**
```bash
# Start with default settings
aim dev

# Custom entry point
aim dev --entry bin/api.dart

# Disable hot reload
aim dev --no-hot-reload

# Watch additional directories
aim dev --watch lib,bin,routes

# Custom port
aim dev --port 3000
```

**How it works:**
- Watches specified directories for file changes
- Automatically restarts the server when files are modified
- Preserves terminal output history
- Loads environment variables from `pubspec.yaml`

### `aim build`

Compile the server for production deployment.

**Usage:**
```bash
aim build [options]
```

**Options:**

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--entry` | `-e` | Server entry point | `bin/server.dart` or `pubspec.yaml` |
| `--output` | `-o` | Output file path | `build/server` |

**Examples:**
```bash
# Build with default settings
aim build

# Custom entry point
aim build --entry bin/api.dart

# Custom output path
aim build --output dist/my-server

# Both custom
aim build --entry bin/api.dart --output dist/api-server
```

**Output:**
```
🔨 Compiling for production...
📁 Entry point: bin/server.dart
📦 Output: build/server

✅ Build successful!

📦 Executable: build/server

Next steps:
  # Run locally
  ./build/server

  # Build Docker image
  docker build -t my-app .
```

## Configuration

### pubspec.yaml

Configure Aim CLI behavior in your `pubspec.yaml`:

```yaml
name: my_app
description: My Aim application

dependencies:
  aim_server: ^0.0.6

# Aim CLI configuration
aim:
  # Entry point (optional)
  entry: bin/server.dart

  # Environment variables (optional)
  env:
    PORT: "8080"
    HOST: "0.0.0.0"
    DATABASE_URL: "postgresql://localhost/mydb"
    JWT_SECRET: ${JWT_SECRET}  # Expand from system environment
```

### Environment Variables

The `aim.env` section supports multiple formats:

**1. Static values:**
```yaml
aim:
  env:
    PORT: "8080"
    ENV: "development"
```

**2. Environment variable expansion:**
```yaml
aim:
  env:
    DATABASE_URL: ${DATABASE_URL}  # Reads from system environment
    JWT_SECRET: ${JWT_SECRET}
    API_KEY: ${API_KEY}
```

**3. Default values:**
```yaml
aim:
  env:
    PORT: ${PORT:8080}              # Use $PORT, fallback to 8080
    HOST: ${HOST:0.0.0.0}           # Use $HOST, fallback to 0.0.0.0
    DATABASE_URL: ${DB_URL:postgresql://localhost/dev}
```

**4. Mixed:**
```yaml
aim:
  env:
    PORT: ${PORT:3000}              # With default
    DATABASE_URL: ${DATABASE_URL}   # Required (no default)
    DEBUG: "true"                   # Static value
```

**Supported formats:**
- `$VAR_NAME` - Simple expansion
- `${VAR_NAME}` - Braces expansion
- `${VAR_NAME:default}` - With default value

When you run `aim dev`, these variables are:
1. Read from `pubspec.yaml`
2. Expanded using system environment variables
3. Merged with existing environment
4. Passed to your application

**Example 1 - With defaults:**
```yaml
# pubspec.yaml
aim:
  env:
    PORT: ${PORT:3000}                    # Defaults to 3000
    DATABASE_URL: ${DB_URL:postgresql://localhost/dev}
    DEBUG: ${DEBUG:false}
```

```bash
# Terminal (no environment variables set)
aim dev

# Your application receives:
# PORT=3000
# DATABASE_URL=postgresql://localhost/dev
# DEBUG=false
```

**Example 2 - Override defaults:**
```yaml
# pubspec.yaml
aim:
  env:
    PORT: ${PORT:3000}
    DATABASE_URL: ${DB_URL:postgresql://localhost/dev}
```

```bash
# Terminal (with environment variables)
export PORT=8080
export DB_URL="postgresql://production/mydb"
aim dev

# Your application receives:
# PORT=8080
# DATABASE_URL=postgresql://production/mydb
```

## Development Workflow

### 1. Create Project

```bash
aim create my_api
cd my_api
```

### 2. Development

```bash
# Start dev server with hot reload
aim dev

# Edit files in lib/ or bin/
# Server automatically restarts
```

### 3. Build for Production

```bash
# Compile to executable
aim build

# Test the build
./build/server

# Deploy
scp build/server user@server:/app/
```

## Tips & Tricks

### Quick Project Setup

```bash
aim create my_app && cd my_app && aim dev
```

### Development with Custom Port

```yaml
# pubspec.yaml
aim:
  env:
    PORT: "3000"
```

```bash
aim dev
# Server runs on port 3000
```

### Multiple Environments

```bash
# Development
aim dev

# Production build
ENV=production aim build
./build/server
```

### Debugging Without Hot Reload

```bash
aim dev --no-hot-reload
# Use Dart debugger in IDE
```

### Watch Specific Directories

```bash
aim dev --watch lib,bin,routes,config
```

### Custom Entry Points

Useful for microservices:

```bash
# API server
aim dev --entry bin/api.dart --port 8080

# Admin server
aim dev --entry bin/admin.dart --port 8081
```

## Troubleshooting

### "pubspec.yaml not found"

Make sure you're in the project root directory:

```bash
cd my_project
aim dev
```

### "Entry point not found"

Check that the entry file exists:

```bash
ls bin/server.dart
# or specify custom entry
aim dev --entry bin/api.dart
```

### Hot Reload Not Working

1. Check you're editing files in watched directories (`lib/`, `bin/`)
2. Try disabling and re-enabling:
   ```bash
   aim dev --no-hot-reload  # Test without
   aim dev                   # Re-enable
   ```

### Port Already in Use

```bash
# Find and kill process
lsof -i :8080
kill -9 <PID>

# Or use different port
aim dev --port 3000
```

### Environment Variables Not Loading

Check your `pubspec.yaml` formatting:

```yaml
aim:
  env:
    PORT: "8080"  # Must be quoted
    DEBUG: "true" # Booleans as strings
```

Make sure system variables are exported:

```bash
export DATABASE_URL="postgresql://localhost/db"
aim dev
```

## Next Steps

- Read the [Quick Start](/getting-started/quick-start) guide
- Learn about [Routing](/concepts/routing)
- Explore [Middleware](/middleware/)
