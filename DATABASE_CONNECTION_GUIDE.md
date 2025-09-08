# Database Connection Guide for Medical Web App

This guide shows you how to connect to different database systems in VS Code and integrate them with your .NET medical application.

## 🔌 **Available Database Options**

### 1. MySQL/MariaDB (Port 3306) - **RECOMMENDED for Production**
### 2. SQLite - **Current Setup (Good for Development)**  
### 3. SQL Server/MSSQL - **Enterprise Option**

---

## 🐬 **Option 1: MySQL Connection (Your Local Instance)**

### **Step 1: Connect in VS Code**

#### Method A: Using SQLTools Extension
1. **Open Command Palette**: `Cmd+Shift+P`
2. Type: `SQLTools: Add New Connection`
3. Select: **MySQL/MariaDB**
4. Configure:
   ```
   Connection name: Medical App MySQL
   Server: localhost
   Port: 3306
   Database: (leave empty to see all databases)
   Username: root
   Password: [your MySQL password]
   ```

#### Method B: Using MySQL Client Extension
1. **Click Database icon** in left sidebar
2. **Click "+" button**
3. Enter connection details:
   ```
   Host: localhost
   Port: 3306
   User: root
   Password: [your password]
   ```

### **Step 2: Update .NET Application**

#### Run the automated setup script:
```bash
./setup-mysql.sh
```

#### Or manually update:

1. **Update appsettings.json**:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Port=3306;Database=MedicalApp;Uid=root;Pwd=YOUR_PASSWORD_HERE;"
  }
}
```

2. **Create MySQL migrations**:
```bash
dotnet ef migrations add InitialMySQLMigration
dotnet ef database update
```

3. **Run application**:
```bash
dotnet run
```

---

## 📱 **Option 2: SQLite Connection (Current Setup)**

### **VS Code Connection**
1. **Install SQLite Extension**:
   - Extension ID: `alexcvzz.vscode-sqlite`
2. **Open database file**:
   - Right-click `MedicalApp.db` → "Open Database"

### **Already Configured in .NET**
- ✅ Currently working
- ✅ File-based database: `MedicalApp.db`
- ✅ Good for development and learning

---

## 🏢 **Option 3: SQL Server/MSSQL Connection**

### **Step 1: Setup SQL Server**
Choose one:
- **Local SQL Server Express** (Free)
- **SQL Server Developer Edition** (Free)
- **Azure SQL Database** (Cloud)

### **Step 2: Connect in VS Code**
1. **Use SQL Server Extension** (already installed)
2. **Command Palette**: `MS SQL: Add Connection`
3. Configure:
   ```
   Server: localhost\SQLEXPRESS
   Database: master
   Authentication: SQL Login / Windows
   Username: sa (if SQL Login)
   Password: [your password]
   ```

### **Step 3: Update .NET Application**
```bash
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
```

Update Program.cs:
```csharp
options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"));
```

---

## 🛠️ **Database Management Commands**

### **General EF Core Commands**
```bash
# Create migration
dotnet ef migrations add MigrationName

# Apply migrations
dotnet ef database update

# Remove last migration
dotnet ef migrations remove

# Generate SQL script
dotnet ef migrations script
```

### **MySQL Specific Commands**
```sql
-- Connect to MySQL
mysql -u root -p

-- Create database
CREATE DATABASE MedicalApp;

-- Use database
USE MedicalApp;

-- Show tables
SHOW TABLES;

-- Show table structure
DESCRIBE Patients;
```

### **SQLite Specific Commands**
```sql
-- Open SQLite database
sqlite3 MedicalApp.db

-- Show tables
.tables

-- Show schema
.schema

-- Import/Export
.dump
```

---

## 🔍 **Testing Database Connection**

### **Test MySQL Connection**
```bash
# Test connection
mysql -u root -p -e "SELECT VERSION();"

# Test specific database
mysql -u root -p -e "USE MedicalApp; SHOW TABLES;"
```

### **Test .NET Connection**
Add this to any controller or page:
```csharp
public async Task<IActionResult> TestConnection()
{
    try
    {
        var patientCount = await _context.Patients.CountAsync();
        return Ok($"Database connected! Patient count: {patientCount}");
    }
    catch (Exception ex)
    {
        return BadRequest($"Database error: {ex.Message}");
    }
}
```

---

## 📊 **Database Comparison**

| Feature | SQLite | MySQL | SQL Server |
|---------|---------|--------|------------|
| **Setup Complexity** | ⭐ Easy | ⭐⭐ Medium | ⭐⭐⭐ Advanced |
| **Performance** | Good | Excellent | Excellent |
| **Scalability** | Limited | High | Very High |
| **Cost** | Free | Free | Express Free |
| **Learning Curve** | Low | Medium | High |
| **Production Ready** | Small apps | Yes | Enterprise |

---

## 🚀 **Recommended Next Steps**

### **For Learning (.NET Basics):**
1. ✅ **Keep SQLite** - Already working
2. Practice CRUD operations
3. Learn Entity Framework concepts

### **For Real Projects:**
1. 🔄 **Switch to MySQL** - Better performance
2. Use the setup script: `./setup-mysql.sh`
3. Learn MySQL administration

### **For Enterprise:**
1. 🏢 **Use SQL Server** - Full features
2. Learn stored procedures
3. Implement advanced security

---

## 🆘 **Troubleshooting**

### **Common MySQL Issues:**
```bash
# Check if MySQL is running
brew services list | grep mysql

# Start MySQL
brew services start mysql

# Reset root password
sudo mysql_secure_installation
```

### **Common .NET Issues:**
```bash
# Clear NuGet cache
dotnet nuget locals all --clear

# Rebuild project
dotnet clean && dotnet build

# Reset EF migrations
rm -rf Migrations/
dotnet ef migrations add Initial
```

### **VS Code Connection Issues:**
1. **Check extension logs**: View → Output → SQLTools
2. **Verify credentials**: Test with command line first
3. **Firewall**: Ensure port 3306 is open
4. **SSL**: Try adding `SslMode=None` to connection string

---

## 📚 **Additional Resources**

- [Entity Framework Core Documentation](https://docs.microsoft.com/en-us/ef/core/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [SQLite Tutorial](https://www.sqlite.org/docs.html)
- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/)

---

**Need Help?** Your current setup with SQLite is perfect for learning. MySQL upgrade is optional but recommended for real projects.
