#!/bin/bash

# Medical Web App - MySQL Setup Script
# This script helps you configure MySQL connection for your medical application

echo "🏥 Medical Web App - MySQL Configuration Helper"
echo "=============================================="

# Check if MySQL is running
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL is not installed or not in PATH"
    exit 1
fi

# Test MySQL connection
echo "🔍 Testing MySQL connection..."
mysql --version

# Prompt for password
echo ""
echo "Please enter your MySQL root password:"
read -s MYSQL_PASSWORD

# Test connection with password
echo "🔗 Testing connection to MySQL..."
mysql -u root -p"$MYSQL_PASSWORD" -e "SELECT VERSION();" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ MySQL connection successful!"
else
    echo "❌ Failed to connect to MySQL. Please check your password."
    exit 1
fi

# Create database if it doesn't exist
echo "🏗️  Creating MedicalApp database..."
mysql -u root -p"$MYSQL_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS MedicalApp;" 2>/dev/null

# Update appsettings.json with the password
echo "⚙️  Updating appsettings.json..."
ESCAPED_PASSWORD=$(printf '%s\n' "$MYSQL_PASSWORD" | sed 's/[[\.*^$()+?{|]/\\&/g')
sed -i.bak "s/Pwd=your_mysql_password_here/Pwd=$ESCAPED_PASSWORD/" appsettings.json

if [ $? -eq 0 ]; then
    echo "✅ Configuration updated successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Run: dotnet ef migrations add InitialMySQLMigration"
    echo "2. Run: dotnet ef database update"
    echo "3. Run: dotnet run"
    echo ""
    echo "🔌 Your MySQL connection string:"
    echo "Server=localhost;Port=3306;Database=MedicalApp;Uid=root;Pwd=$MYSQL_PASSWORD;"
else
    echo "❌ Failed to update configuration file"
    exit 1
fi
