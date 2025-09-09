#!/bin/bash

# Railway Startup Diagnostic Script
echo "🚀 Medical Web App - Railway Startup Check"
echo "==========================================="

echo "📊 Environment Variables:"
echo "PORT: ${PORT:-"Not Set"}"
echo "DATABASE_URL: ${DATABASE_URL:0:20}... (first 20 chars)"
echo "ASPNETCORE_ENVIRONMENT: ${ASPNETCORE_ENVIRONMENT:-"Not Set"}"
echo "ASPNETCORE_URLS: ${ASPNETCORE_URLS:-"Not Set"}"

echo ""
echo "🌐 Network Configuration:"
echo "Hostname: $(hostname)"
echo "IP Addresses: $(hostname -I 2>/dev/null || echo 'N/A')"

echo ""
echo "📁 Application Files:"
ls -la /app/ 2>/dev/null || echo "App directory not found"

echo ""
echo "🔍 Process Status:"
ps aux | grep -E "(dotnet|Medical)" | head -5

echo ""
echo "🗄️ Database Connection Test:"
if [ -n "$DATABASE_URL" ]; then
    echo "DATABASE_URL is configured"
else
    echo "❌ DATABASE_URL is not set!"
fi

echo ""
echo "✅ Starting Medical Web Application..."
