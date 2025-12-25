# test_aim_build

A web server project built with Aim framework.

## Setup

Install dependencies:
```bash
dart pub get
```

## Development

Start development server with hot reload:
```bash
aim dev
```

Or run directly:
```bash
dart run bin/server.dart
```

## Production Build

### Option 1: Native Executable

Compile to a native executable:
```bash
aim build
```

Run the executable:
```bash
./build/server
```

### Option 2: Docker

Build Docker image:
```bash
docker build -t test_aim_build .
```

Run container:
```bash
docker run -p 8080:8080 test_aim_build
```

## Test

```bash
dart test
```

## Project Structure

- `bin/server.dart` - Server entry point
- `lib/src/server.dart` - Server implementation
- `test/test_aim_build_test.dart` - Test files
- `Dockerfile` - Docker configuration for production
- `.dockerignore` - Files to exclude from Docker build

## About Aim Framework

For more details, see [Aim Documentation](https://github.com/yourusername/aim).
