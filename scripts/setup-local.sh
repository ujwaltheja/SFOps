#!/bin/bash
set -e

echo "🚀 Setting up SFOps local development environment..."

# Check prerequisites
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed. Aborting." >&2; exit 1; }

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "❌ Node.js 20+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Install dependencies
echo "📦 Installing npm dependencies..."
npm install

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "⚠️  Please update .env with your configuration"
fi

# Start infrastructure services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check PostgreSQL
echo "🔍 Checking PostgreSQL..."
until docker-compose exec -T postgres pg_isready -U sfops > /dev/null 2>&1; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done
echo "✅ PostgreSQL is ready"

# Check Redis
echo "🔍 Checking Redis..."
until docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; do
    echo "Waiting for Redis..."
    sleep 2
done
echo "✅ Redis is ready"

# Run database migrations
echo "🗄️  Running database migrations..."
npm run db:migrate

# Seed database (optional)
read -p "Do you want to seed the database with demo data? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🌱 Seeding database..."
    npm run db:seed
fi

# Create S3 bucket in MinIO
echo "📦 Creating S3 bucket..."
docker-compose exec -T minio mc alias set local http://localhost:9000 minio minio123 || true
docker-compose exec -T minio mc mb local/sfops-snapshots || true

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Update .env with your configuration"
echo "   2. Run 'npm run dev' to start development servers"
echo ""
echo "📚 Services available at:"
echo "   - API: http://localhost:3000"
echo "   - Frontend: http://localhost:5173"
echo "   - GraphQL: http://localhost:3000/graphql"
echo "   - Temporal UI: http://localhost:8088"
echo "   - Grafana: http://localhost:3001 (admin/admin)"
echo "   - MinIO Console: http://localhost:9001 (minio/minio123)"
echo ""
