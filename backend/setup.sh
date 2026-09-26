#!/usr/bin/env bash
# FreeTier Radar — Backend quickstart script
# Usage: bash setup.sh

set -euo pipefail

echo "📡 FreeTier Radar Backend Setup"
echo "================================"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.11+."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "✓ Python $PYTHON_VERSION detected"

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate
source venv/bin/activate
echo "✓ Virtual environment activated"

# Install dependencies
echo "📦 Installing dependencies..."
pip install -q -r requirements.txt
echo "✓ Dependencies installed"

# Copy .env if not exists
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✓ Created .env from .env.example"
fi

# Seed database
if [ ! -f "freetier_radar.db" ]; then
    echo "🌱 Seeding database..."
    python seed_data.py
    echo "✓ Database seeded"
else
    echo "ℹ️  Database already exists (freetier_radar.db)"
fi

echo ""
echo "🚀 Ready! Start the server with:"
echo "   source venv/bin/activate"
echo "   uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo "📖 API docs: http://localhost:8000/docs"
