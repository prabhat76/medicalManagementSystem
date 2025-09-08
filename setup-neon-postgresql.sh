#!/bin/bash

# Neon PostgreSQL Database Setup Script
# Medical Web Application - Production Configuration

echo "🏥 Medical Web App - Neon PostgreSQL Setup"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up Neon PostgreSQL connection...${NC}"

# Neon Database Details (from screenshot)
DB_HOST="ep-orange-shadow-a5pnm2by.us-east-2.aws.neon.tech"
DB_NAME="shiny-haze-01587706"
DB_USER="shiny-haze-01587706_owner"
DB_REGION="US East (Ohio)"

echo ""
echo "📋 Database Information:"
echo "   Host: $DB_HOST"
echo "   Database: $DB_NAME"
echo "   Username: $DB_USER"
echo "   Region: $DB_REGION"
echo ""

# Get password from user
echo -e "${YELLOW}Please enter your Neon database password:${NC}"
read -s DB_PASSWORD

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}❌ Password cannot be empty!${NC}"
    exit 1
fi

# Create connection string
CONNECTION_STRING="Host=$DB_HOST;Database=$DB_NAME;Username=$DB_USER;Password=$DB_PASSWORD;SSL Mode=Require;Trust Server Certificate=true;"

# Update appsettings.Production.json
echo -e "${GREEN}✅ Updating production configuration...${NC}"

cat > appsettings.Production.json << EOF
{
  "ConnectionStrings": {
    "DefaultConnection": "$CONNECTION_STRING",
    "PostgreSQLConnection": "$CONNECTION_STRING"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore.Database.Command": "Information"
    }
  },
  "AllowedHosts": "*"
}
EOF

echo -e "${GREEN}✅ Production configuration updated!${NC}"

# Test connection
echo -e "${YELLOW}🔌 Testing database connection...${NC}"

# Set environment for production
export ASPNETCORE_ENVIRONMENT=Production

# Run migration
echo -e "${YELLOW}📊 Running database migrations...${NC}"
dotnet ef database update --context MedicalDbContext

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database migration completed successfully!${NC}"
    echo ""
    echo -e "${GREEN}🎉 Neon PostgreSQL Setup Complete!${NC}"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Your app is now configured for Neon PostgreSQL"
    echo "   2. Run: ASPNETCORE_ENVIRONMENT=Production dotnet run"
    echo "   3. Your medical app will use the cloud database"
    echo ""
    echo "🔗 Connection Details:"
    echo "   - Host: $DB_HOST"
    echo "   - Database: $DB_NAME"
    echo "   - SSL: Enabled (Required for Neon)"
    echo ""
else
    echo -e "${RED}❌ Migration failed! Check your connection details.${NC}"
    exit 1
fi

# Clean up
unset DB_PASSWORD
unset CONNECTION_STRING

echo -e "${GREEN}🔒 Setup completed securely!${NC}"
