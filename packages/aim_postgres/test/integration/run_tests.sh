#!/bin/bash

set -e

echo "🐳 Starting PostgreSQL container..."
docker-compose -f test/integration/docker-compose.yml up -d

echo "⏳ Waiting for PostgreSQL to be ready..."
timeout=30
elapsed=0
until docker exec aim_orm_postgres_test pg_isready -U test > /dev/null 2>&1; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [ $elapsed -ge $timeout ]; then
    echo "❌ PostgreSQL failed to start within ${timeout} seconds"
    docker-compose -f test/integration/docker-compose.yml down
    exit 1
  fi
done
echo "✅ PostgreSQL is ready!"

echo ""
echo "🧪 Running unit tests..."
dart test test/unit/

echo ""
echo "🧪 Running integration tests..."
dart test test/integration/

echo ""
echo "🧹 Stopping PostgreSQL container..."
docker-compose -f test/integration/docker-compose.yml down

echo ""
echo "✅ All tests completed successfully!"
