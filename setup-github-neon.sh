#!/bin/bash

# GitHub + Neon Integration Setup Script
# Medical Web Application - GitHub Integration

echo "🐙 Medical Web App - GitHub + Neon Integration Setup"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up GitHub + Neon PostgreSQL integration...${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Not a git repository! Please run 'git init' first.${NC}"
    exit 1
fi

# Get repository information
REPO_URL=$(git config --get remote.origin.url)
CURRENT_BRANCH=$(git branch --show-current)

echo "📋 Repository Information:"
echo "   Remote: $REPO_URL"
echo "   Branch: $CURRENT_BRANCH"
echo ""

echo -e "${YELLOW}🔧 GitHub Integration Setup${NC}"
echo ""
echo "To complete the GitHub + Neon integration, you'll need to:"
echo ""
echo "1. 📱 Set up GitHub Repository Secrets:"
echo "   Go to: GitHub Repository → Settings → Secrets and variables → Actions"
echo ""
echo "2. 🔑 Add the following secret:"
echo "   Name: DATABASE_URL"
echo "   Value: Your Neon connection string from the dashboard"
echo ""
echo "3. 📝 Neon Connection String Format:"
echo "   Host=ep-orange-shadow-a5pnm2by.us-east-2.aws.neon.tech;Database=shiny-haze-01587706;Username=shiny-haze-01587706_owner;Password=YOUR_PASSWORD;SSL Mode=Require;Trust Server Certificate=true;"
echo ""

# Check if GitHub CLI is available
if command -v gh &> /dev/null; then
    echo -e "${GREEN}✅ GitHub CLI detected!${NC}"
    echo ""
    echo "🚀 Quick Setup Option:"
    echo "   You can use GitHub CLI to set the secret:"
    echo ""
    echo -e "${YELLOW}   gh secret set DATABASE_URL${NC}"
    echo ""
    read -p "Would you like to set the DATABASE_URL secret now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Please paste your Neon connection string:"
        read -s DATABASE_URL
        echo ""
        gh secret set DATABASE_URL --body "$DATABASE_URL"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ DATABASE_URL secret set successfully!${NC}"
        else
            echo -e "${RED}❌ Failed to set secret. You can set it manually in GitHub.${NC}"
        fi
    fi
else
    echo -e "${YELLOW}💡 Install GitHub CLI for easier secret management:${NC}"
    echo "   brew install gh"
    echo ""
fi

# Create environment file for local development
echo -e "${YELLOW}🔧 Setting up local development environment...${NC}"

# Check if .env file exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists. Backing up..."
    cp .env .env.backup
fi

cat > .env << 'EOF'
# Local Development Environment
# DO NOT COMMIT THIS FILE TO GIT

# Database Configuration
# For local development with MySQL
DATABASE_URL_LOCAL=Server=localhost;Port=3306;Database=MedicalApp;Uid=root;Pwd=your_password;

# For testing with Neon PostgreSQL locally
# DATABASE_URL=Host=ep-orange-shadow-a5pnm2by.us-east-2.aws.neon.tech;Database=shiny-haze-01587706;Username=shiny-haze-01587706_owner;Password=YOUR_PASSWORD;SSL Mode=Require;Trust Server Certificate=true;

# ASP.NET Core Environment
ASPNETCORE_ENVIRONMENT=Development
EOF

echo -e "${GREEN}✅ Created .env file for local development${NC}"

# Update .gitignore
if [ ! -f ".gitignore" ]; then
    echo "Creating .gitignore file..."
    cat > .gitignore << 'EOF'
# .NET
bin/
obj/
*.user
*.suo
*.cache
*.docstates
_ReSharper.*
*.csproj.user
*.build.csdef
*.publish.xml
*.publishsettings
*.pubxml

# Environment files
.env
.env.local
.env.production
*.env

# Database
*.db
*.sqlite
*.sqlite3

# IDE
.vs/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF
else
    # Add environment files to .gitignore if not already there
    if ! grep -q ".env" .gitignore; then
        echo "" >> .gitignore
        echo "# Environment files" >> .gitignore
        echo ".env" >> .gitignore
        echo ".env.*" >> .gitignore
        echo "*.env" >> .gitignore
    fi
fi

echo -e "${GREEN}✅ Updated .gitignore${NC}"

# Test local build
echo -e "${YELLOW}🔨 Testing local build...${NC}"
dotnet build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Local build successful!${NC}"
else
    echo -e "${RED}❌ Build failed. Please check for errors.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 GitHub + Neon Integration Setup Complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. 🔑 Set up GitHub Secret:"
echo "   - Go to GitHub Repository → Settings → Secrets"
echo "   - Add secret: DATABASE_URL with your Neon connection string"
echo ""
echo "2. 🚀 Deploy via GitHub:"
echo "   git add ."
echo "   git commit -m 'Add Neon PostgreSQL integration'"
echo "   git push origin $CURRENT_BRANCH"
echo ""
echo "3. 🌐 GitHub Actions will automatically:"
echo "   - Build your application"
echo "   - Run database migrations"
echo "   - Deploy to your hosting platform"
echo ""
echo "4. 💻 For local development:"
echo "   - Edit .env file with your local database settings"
echo "   - Use: dotnet run (will use local MySQL/SQLite)"
echo ""
echo "🔗 Your app will automatically use:"
echo "   - 🌐 Neon PostgreSQL in production (via DATABASE_URL)"
echo "   - 💻 Local database for development"
echo ""
echo -e "${BLUE}💡 Pro Tip: Use GitHub branches to test different features!${NC}"
echo "   - Neon supports database branching"
echo "   - Each PR can have its own database branch"
echo ""

echo -e "${GREEN}🔒 Setup completed securely!${NC}"
