#!/bin/bash

# Netlify Build Script for Medical Web Application
echo "🏥 Building Medical Web Application..."

# Check .NET installation
echo "📋 Checking .NET installation..."
dotnet --version

# Install EF Core tools if needed
echo "🔧 Installing Entity Framework tools..."
dotnet tool install --global dotnet-ef --version 9.0.0 || echo "EF tools already installed"

# Add tools to PATH
export PATH="$PATH:/opt/buildhome/.dotnet/tools"

# Restore dependencies
echo "📦 Restoring dependencies..."
dotnet restore ./MedicalWebApp.csproj

# Build the application
echo "🔨 Building application..."
dotnet build ./MedicalWebApp.csproj --configuration Release --no-restore

# Run database migrations (if DATABASE_URL is available)
if [ ! -z "$NETLIFY_DATABASE_URL" ]; then
    echo "🗄️ Running database migrations..."
    export DATABASE_URL=$NETLIFY_DATABASE_URL
    dotnet ef database update --context MedicalDbContext --project ./MedicalWebApp.csproj
else
    echo "⚠️ No database URL found, skipping migrations"
fi

# Publish the application
echo "📦 Publishing application..."
dotnet publish ./MedicalWebApp.csproj -c Release -o ./publish --no-build

echo "✅ Build completed successfully!"
echo "📁 Published files are in ./publish/"
