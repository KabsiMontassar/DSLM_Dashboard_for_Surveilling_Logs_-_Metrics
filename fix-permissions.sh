#!/bin/bash
# DSLM Permission Fix Script
# Fixes directory permissions for Docker containers

echo "🔧 Fixing DSLM Directory Permissions"
echo "===================================="

# Fix Grafana permissions (user ID 472)
echo "📊 Setting Grafana permissions..."
sudo chown -R 472:472 ./data/grafana 2>/dev/null && echo "✅ Grafana permissions fixed" || echo "❌ Failed to fix Grafana permissions"

# Fix Prometheus permissions (user ID 65534 - nobody)
echo "📈 Setting Prometheus permissions..."
sudo chown -R 65534:65534 ./data/prometheus 2>/dev/null && echo "✅ Prometheus permissions fixed" || echo "❌ Failed to fix Prometheus permissions"

# Fix Loki permissions (user ID 10001)
echo "📝 Setting Loki permissions..."
sudo chown -R 10001:10001 ./data/loki 2>/dev/null && echo "✅ Loki permissions fixed" || echo "❌ Failed to fix Loki permissions"

# Fix Tempo permissions (user ID 10001)
echo "🔍 Setting Tempo permissions..."
sudo chown -R 10001:10001 ./data/tempo 2>/dev/null && echo "✅ Tempo permissions fixed" || echo "❌ Failed to fix Tempo permissions"

# Make directories accessible
echo "🔓 Setting directory access permissions..."
chmod -R 755 ./data/ 2>/dev/null && echo "✅ Directory access permissions set" || echo "❌ Failed to set directory permissions"

echo ""
echo "🎉 Permission fix complete!"
echo "Now run: docker-compose up -d"