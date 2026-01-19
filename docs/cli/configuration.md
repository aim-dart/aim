---
title: CLI Configuration - Aim
description: Configure Aim CLI via pubspec.yaml. Entry points, environment variables, and development settings.
head:
  - - meta
    - name: keywords
      content: Aim CLI config, pubspec.yaml, environment variables, Dart configuration
---

# Configuration

Configure Aim CLI via `pubspec.yaml`.

## Basic Configuration

```yaml
name: my_app
description: My Aim application

dependencies:
  aim_server: ^0.0.6

aim:
  entry: bin/server.dart
```

## Environment Variables

### Static Values

```yaml
aim:
  entry: bin/server.dart
  env:
    PORT: "8080"
    HOST: "0.0.0.0"
    ENV: "development"
```

### Environment Variable Expansion

You can expand system environment variables:

```yaml
aim:
  env:
    DATABASE_URL: ${DATABASE_URL}
    JWT_SECRET: ${JWT_SECRET}
    API_KEY: ${API_KEY}
```

### Default Values

Default values when environment variables are not set:

```yaml
aim:
  env:
    PORT: ${PORT:8080}
    HOST: ${HOST:0.0.0.0}
    DATABASE_URL: ${DB_URL:postgresql://localhost/dev}
```

### Combined Example

```yaml
aim:
  entry: bin/server.dart
  env:
    # Static values
    ENV: "development"

    # With defaults
    PORT: ${PORT:8080}
    HOST: ${HOST:0.0.0.0}

    # Required (no default)
    DATABASE_URL: ${DATABASE_URL}
    JWT_SECRET: ${JWT_SECRET}
```

## Variable Expansion Formats

| Format | Description |
|--------|-------------|
| `$VAR_NAME` | Simple expansion |
| `${VAR_NAME}` | Braces expansion |
| `${VAR_NAME:default}` | With default value |

## How It Works

When running `aim dev`:

1. Load `aim.env` from `pubspec.yaml`
2. Expand `${VAR}` with system environment variables
3. Merge with existing environment variables
4. Pass to application

## Example Workflow

### Development

```yaml
# pubspec.yaml
aim:
  entry: bin/server.dart
  env:
    PORT: ${PORT:3000}
    DATABASE_URL: ${DB_URL:postgresql://localhost/dev}
    DEBUG: "true"
```

```bash
# Uses defaults
aim dev
# PORT=3000, DATABASE_URL=postgresql://localhost/dev, DEBUG=true
```

### Production

```bash
# Override with environment variables
export PORT=8080
export DB_URL="postgresql://prod-server/mydb"
aim dev
# PORT=8080, DATABASE_URL=postgresql://prod-server/mydb, DEBUG=true
```

## Entry Point Resolution

Entry point is determined in this order:

1. `--entry` option (`aim dev --entry bin/api.dart`)
2. `aim.entry` in `pubspec.yaml`
3. Default: `bin/server.dart`

## Watch Directories

Directories watched by `aim dev`:

- Default: `lib`, `bin`
- Customizable with `--watch` option

```bash
aim dev --watch lib,bin,routes,config
```

## Next Steps

- [Commands](/cli/commands) - CLI command reference
- [Server Quick Start](/server/quick-start) - Build your first app
