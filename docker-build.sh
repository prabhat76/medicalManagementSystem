#!/bin/bash

# Docker Build Script for Medical Web Application

echo "🏥 Building Medical Web Application Docker Image..."

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t medical-web-app .

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
    echo ""
    echo "🚀 To run the container locally:"
    echo "docker run -d -p 8080:8080 --name medical-app medical-web-app"
    echo ""
    echo "🌐 Access the application at: http://localhost:8080"
    echo ""
    echo "🗄️ To run with database connection:"
    echo "docker run -d -p 8080:8080 -e DATABASE_URL='your-connection-string' --name medical-app medical-web-app"
else
    echo "❌ Docker build failed!"
    echo "Check the error messages above for details."
    exit 1
fi
