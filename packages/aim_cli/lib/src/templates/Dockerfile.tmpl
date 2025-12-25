# Official Dart image: https://hub.docker.com/_/dart
FROM dart:stable AS build

WORKDIR /app

# Copy and resolve dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy app source code
COPY . .

# Ensure packages are up-to-date
RUN dart pub get --offline

# Compile to native executable
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled binary
FROM scratch

# Copy runtime dependencies and compiled binary
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# Expose port (default: 8080)
EXPOSE 8080

# Start server
CMD ["/app/bin/server"]
