# Medical Web Application

A .NET learning project that demonstrates web development concepts using ASP.NET Core Razor Pages, designed for medical practice management.

## Overview

This project serves as an introduction to .NET web development, specifically mimicking Web Forms functionality using modern ASP.NET Core Razor Pages. It's designed for learning purposes with a medical application theme.

## Features

### Implemented
- ✅ Patient Registration Form
- ✅ Responsive Bootstrap UI
- ✅ Form Validation
- ✅ Medical-themed Dashboard

### Planned
- 📋 Appointment Scheduling
- 📋 Patient Records Management  
- 📋 Doctor Management
- 📋 Medical History Tracking
- 📋 Database Integration

## Technology Stack

- **Framework**: ASP.NET Core 9.0
- **Language**: C#
- **UI**: Razor Pages + Bootstrap 5
- **Platform**: Cross-platform (.NET Core)

## Project Structure

```
├── Models/                 # Data models (Patient, Appointment)
├── Pages/                  # Razor Pages (Views + Code-behind)
│   ├── Shared/            # Shared layouts and partials
│   ├── Index.cshtml       # Dashboard/Home page
│   └── PatientRegistration.cshtml # Patient registration form
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
