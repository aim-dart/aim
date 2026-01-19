---
title: CLI Installation - Aim
description: Install the Aim CLI tool for project scaffolding, development server, and production builds.
head:
  - - meta
    - name: keywords
      content: Dart CLI install, aim_cli setup, Dart development tools
---

# Installation

## Global Installation

Install Aim CLI globally:

```bash
dart install aim_cli
```

## Verify Installation

```bash
aim --version
```

Output:
```
aim_cli 0.0.2
```

## PATH Configuration

To use globally installed commands, add Dart's pub-cache/bin directory to your PATH.

### macOS / Linux

```bash
# ~/.bashrc or ~/.zshrc
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Windows

```powershell
# PowerShell
$env:PATH += ";$env:APPDATA\Pub\Cache\bin"
```

## Update

Update to the latest version:

```bash
dart install aim_cli
```

## Uninstall

```bash
dart pub global deactivate aim_cli
```

## Next Steps

- [Commands](/cli/commands) - Available CLI commands
- [Configuration](/cli/configuration) - Environment setup
