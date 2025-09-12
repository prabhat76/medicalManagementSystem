# Medical Web Application

A .NET learning project that demonstrates web development concepts using ASP.NET Core Razor Pages, designed for medical practice management.

## Overview

This project serves as an introduction to .NET web development, specifically mimicking Web Forms functionality using modern ASP.NET Core Razor Pages. It's designed for learning purposes with a medical application theme.

## Features

### Implemented
- ✅ Patient Registration Form
- ✅ Patient Management (View/Search)
- ✅ Responsive Bootstrap UI
- ✅ Form Validation
- ✅ Database Integration (SQLite/PostgreSQL)
- ✅ Medical-themed Dashboard
- ✅ Unit Tests

### Planned
- 📋 Appointment Scheduling
- 📋 Patient Records Management  
- 📋 Doctor Management
- 📋 Medical History Tracking
- 📋 Database Integration

## Technology Stack

- **Framework**: ASP.NET Core 8.0
- **Language**: C#
- **UI**: Razor Pages + Bootstrap 5
- **Database**: SQLite (development), PostgreSQL (production)
- **Platform**: Cross-platform (.NET Core)
- **Testing**: xUnit with Entity Framework InMemory provider

## Project Structure

```
├── Models/                 # Data models (Patient, Appointment)
├── Pages/                  # Razor Pages (Views + Code-behind)
│   ├── Shared/            # Shared layouts and partials
│   ├── Index.cshtml       # Dashboard/Home page
│   └── PatientRegistration.cshtml # Patient registration form
├── Services/               # Business logic services
├── Data/                   # Entity Framework DbContext
├── Tests/                  # Unit tests
├── wwwroot/               # Static files (CSS, JS, images)
└── Program.cs             # Application startup
```

## Getting Started

### Prerequisites
- .NET 9.0 SDK or later
- Any code editor (VS Code, Visual Studio, etc.)

### Running the Application

1. **Build the project:**
   ```bash
   dotnet build
   ```

2. **Run the application:**
   ```bash
   dotnet run
   ```

3. **Open in browser:**
   - Navigate to `https://localhost:7xxx` (port will be shown in terminal)
   - Or use `http://localhost:5xxx` for non-HTTPS

### Development Commands

```bash
# Build the project
dotnet build

# Run the application
dotnet run

# Run with hot reload (watches for changes)
dotnet watch run

# Run tests
dotnet test

# Run tests with detailed output
dotnet test --logger "console;verbosity=detailed"

# Create a new Razor page
dotnet new page -n NewPageName -o Pages

# Add a NuGet package
dotnet add package PackageName
```

## Learning Objectives

This project helps you learn:

1. **ASP.NET Core Basics**
   - Razor Pages architecture
   - Model binding
   - Form handling

2. **Web Development Concepts**
   - Form validation
   - Responsive design
   - MVC pattern

3. **C# Programming**
   - Object-oriented programming
   - Data annotations
   - LINQ (when database is added)

4. **Testing**
   - Unit testing with xUnit
   - Entity Framework InMemory testing
   - Test-driven development concepts

## Testing

The project includes comprehensive unit tests for both models and services:

```bash
# Run all tests
dotnet test

# Run tests with detailed output
dotnet test --logger "console;verbosity=detailed"

# Run tests with coverage (if coverlet is installed)
dotnet test --collect:"XPlat Code Coverage"
```

### Test Structure
- `Tests/PatientModelTests.cs` - Tests for Patient model validation
- `Tests/PatientServiceTests.cs` - Tests for patient business logic

The tests use:
- **xUnit** - Testing framework
- **Entity Framework InMemory** - For database testing without actual database
- **Data Annotations** - For model validation testing

## Key Differences from Web Forms

| Web Forms | Razor Pages |
|-----------|-------------|
| .aspx + .aspx.cs | .cshtml + .cshtml.cs |
| ViewState | Stateless |
| Server controls | HTML helpers / Tag helpers |
| Page lifecycle events | OnGet/OnPost methods |
| Windows only | Cross-platform |

## Next Steps

1. **Database Integration**: Add Entity Framework Core
2. **Authentication**: Implement user login/registration
3. **API Development**: Create REST APIs
4. **Advanced UI**: Add JavaScript interactions
5. **Deployment**: Deploy to Azure or other cloud platforms

## Resources

- [ASP.NET Core Documentation](https://docs.microsoft.com/en-us/aspnet/core/)
- [Razor Pages Tutorial](https://docs.microsoft.com/en-us/aspnet/core/tutorials/razor-pages/)
- [Bootstrap Documentation](https://getbootstrap.com/docs/)
- [C# Programming Guide](https://docs.microsoft.com/en-us/dotnet/csharp/)

## License

This project is for educational purposes only.
