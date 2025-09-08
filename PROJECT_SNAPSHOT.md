# Medical Web Application - Project Snapshot
**Snapshot Date**: September 8, 2025  
**Version**: 1.0.0

## 📸 Application Screenshots & Code Snapshots

### 🏠 Home Page Structure
**File**: `/Pages/Index.cshtml`
```html
@page
@model IndexModel
@{
    ViewData["Title"] = "Medical Web Application";
}

<div class="container">
    <div class="jumbotron bg-primary text-white p-5 rounded">
        <h1 class="display-4">Medical Web Application</h1>
        <p class="lead">Modern patient management system built with ASP.NET Core</p>
        <hr class="my-4">
        <p>Register patients, manage appointments, and maintain medical records.</p>
        <div class="d-flex gap-3">
            <a asp-page="/PatientRegistration" class="btn btn-light btn-lg">
                <i class="fas fa-user-plus me-2"></i>Register Patient
            </a>
            <a asp-page="/Patients" class="btn btn-outline-light btn-lg">
                <i class="fas fa-users me-2"></i>View Patients
            </a>
        </div>
    </div>
</div>
```

### 👤 Patient Registration Form
**File**: `/Pages/PatientRegistration.cshtml` (Key sections)
```html
<div class="card">
    <div class="card-header">
        <h2 class="text-center">Patient Registration</h2>
    </div>
    <div class="card-body">
        <!-- Success Message -->
        @if (Model.IsSuccess)
        {
            <div class="alert alert-success alert-dismissible fade show">
                <i class="fas fa-check-circle me-2"></i>
                <strong>Success!</strong> Patient registration completed!
                <strong>Patient ID:</strong> @Model.NewPatientId.Value
            </div>
        }

        <!-- Form Fields -->
        <div class="row">
            <div class="col-md-6 mb-3">
                <label asp-for="Patient.FirstName" class="form-label"></label>
                <input asp-for="Patient.FirstName" class="form-control" />
                <span asp-validation-for="Patient.FirstName" class="text-danger"></span>
            </div>
            <div class="col-md-6 mb-3">
                <label asp-for="Patient.LastName" class="form-label"></label>
                <input asp-for="Patient.LastName" class="form-control" />
                <span asp-validation-for="Patient.LastName" class="text-danger"></span>
            </div>
        </div>

        <!-- Email with Enhanced Validation -->
        <div class="mb-3">
            <label asp-for="Patient.Email" class="form-label">
                <i class="fas fa-envelope me-1"></i>Email Address
            </label>
            <input asp-for="Patient.Email" class="form-control" placeholder="patient@example.com" />
            <span asp-validation-for="Patient.Email" class="text-danger"></span>
            <div class="form-text">
                <small><i class="fas fa-info-circle me-1"></i>Email must be unique</small>
            </div>
        </div>
    </div>
</div>
```

### 🗂️ Patient Model Structure
**File**: `/Models/Patient.cs`
```csharp
using System.ComponentModel.DataAnnotations;

namespace MedicalWebApp.Models
{
    public class Patient
    {
        public int Id { get; set; }
        
        [Required(ErrorMessage = "First name is required")]
        [StringLength(100, ErrorMessage = "First name cannot exceed 100 characters")]
        public string FirstName { get; set; } = "";
        
        [Required(ErrorMessage = "Last name is required")]
        [StringLength(100, ErrorMessage = "Last name cannot exceed 100 characters")]
        public string LastName { get; set; } = "";
        
        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Please enter a valid email address")]
        [StringLength(200, ErrorMessage = "Email cannot exceed 200 characters")]
        public string Email { get; set; } = "";
        
        [Required(ErrorMessage = "Phone number is required")]
        [Phone(ErrorMessage = "Please enter a valid phone number")]
        [StringLength(20, ErrorMessage = "Phone number cannot exceed 20 characters")]
        public string PhoneNumber { get; set; } = "";
        
        [Required(ErrorMessage = "Date of birth is required")]
        [DataType(DataType.Date)]
        public DateTime DateOfBirth { get; set; }
        
        [StringLength(500, ErrorMessage = "Address cannot exceed 500 characters")]
        public string? Address { get; set; }
        
        public string? MedicalHistory { get; set; }
        
        public DateTime RegistrationDate { get; set; } = DateTime.Now;
        
        // Navigation property for appointments
        public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
        
        // Computed property for display
        public string FullName => $"{FirstName} {LastName}";
        
        // Computed property for age calculation
        public int Age
        {
            get
            {
                var today = DateTime.Today;
                var age = today.Year - DateOfBirth.Year;
                if (DateOfBirth.Date > today.AddYears(-age)) age--;
                return age;
            }
        }
    }
}
```

### 🏥 Database Context Configuration
**File**: `/Data/MedicalDbContext.cs`
```csharp
using Microsoft.EntityFrameworkCore;
using MedicalWebApp.Models;

namespace MedicalWebApp.Data
{
    public class MedicalDbContext : DbContext
    {
        public MedicalDbContext(DbContextOptions<MedicalDbContext> options) : base(options) { }

        public DbSet<Patient> Patients { get; set; }
        public DbSet<Appointment> Appointments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Patient configuration
            modelBuilder.Entity<Patient>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.FirstName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.LastName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.Email).IsRequired().HasMaxLength(200);
                entity.HasIndex(e => e.Email).IsUnique(); // Unique email constraint
                entity.Property(e => e.PhoneNumber).IsRequired().HasMaxLength(20);
                entity.Property(e => e.Address).HasMaxLength(500);
                entity.Property(e => e.MedicalHistory).HasColumnType("TEXT");
                entity.Property(e => e.RegistrationDate).HasDefaultValueSql("NOW()");
            });

            // Appointment configuration
            modelBuilder.Entity<Appointment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.DoctorName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.Reason).HasMaxLength(500);
                entity.Property(e => e.Notes).HasColumnType("TEXT");
                entity.Property(e => e.CreatedDate).HasDefaultValueSql("NOW()");
                
                // Foreign key relationship
                entity.HasOne<Patient>()
                      .WithMany(p => p.Appointments)
                      .HasForeignKey(a => a.PatientId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
```

### 🔧 Enhanced Patient Service
**File**: `/Services/PatientService.cs` (Key methods)
```csharp
public async Task<int> AddPatientAsync(Patient patient)
{
    // Check if email already exists
    var existingPatient = await GetPatientByEmailAsync(patient.Email);
    if (existingPatient != null)
    {
        throw new InvalidOperationException($"A patient with email '{patient.Email}' already exists.");
    }

    patient.RegistrationDate = DateTime.Now;
    _context.Patients.Add(patient);
    await _context.SaveChangesAsync();
    return patient.Id;
}

public async Task<Patient?> GetPatientByEmailAsync(string email)
{
    return await _context.Patients
        .FirstOrDefaultAsync(p => p.Email.ToLower() == email.ToLower());
}

public async Task<bool> IsEmailUniqueAsync(string email, int? excludePatientId = null)
{
    var query = _context.Patients.Where(p => p.Email.ToLower() == email.ToLower());
    
    if (excludePatientId.HasValue)
    {
        query = query.Where(p => p.Id != excludePatientId.Value);
    }
    
    return !await query.AnyAsync();
}
```

## 🗃️ Database Schema Snapshot

### MySQL Database Structure
```sql
-- Patients Table
CREATE TABLE `patients` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `FirstName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `LastName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `Email` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `PhoneNumber` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DateOfBirth` datetime(6) NOT NULL,
  `Address` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `MedicalHistory` text,
  `RegistrationDate` datetime(6) NOT NULL DEFAULT (now()),
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_Patients_Email` (`Email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Appointments Table
CREATE TABLE `appointments` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `PatientId` int NOT NULL,
  `DoctorName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `AppointmentDate` datetime(6) NOT NULL,
  `Reason` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `Status` int NOT NULL,
  `Notes` text,
  `CreatedDate` datetime(6) NOT NULL DEFAULT (now()),
  PRIMARY KEY (`Id`),
  KEY `IX_Appointments_PatientId` (`PatientId`),
  CONSTRAINT `FK_Appointments_Patients_PatientId` FOREIGN KEY (`PatientId`) REFERENCES `patients` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

## 📊 Project Statistics

### Code Metrics
- **Total Files**: 25+ source files
- **Lines of Code**: ~1,500+ lines
- **Languages**: C#, HTML, CSS, SQL
- **Frameworks**: ASP.NET Core 9.0, Entity Framework Core, Bootstrap 5

### Database Metrics
- **Tables**: 2 (Patients, Appointments)
- **Relationships**: 1 (One-to-Many: Patient → Appointments)
- **Constraints**: Primary Keys, Foreign Keys, Unique Email
- **Indexes**: Email uniqueness, Patient ID foreign key

### Features Implemented
- ✅ Patient Registration (Complete)
- ✅ Patient Listing (Complete)
- ✅ Database Integration (Complete)
- ✅ Error Handling (Enhanced)
- ✅ Data Validation (Comprehensive)
- ✅ Responsive UI (Complete)
- 🔄 Appointment System (Structure Ready)

## 🔗 Application URLs
- **Home**: `http://localhost:5270/`
- **Patient Registration**: `http://localhost:5270/PatientRegistration`
- **Patient List**: `http://localhost:5270/Patients`

## 💾 Configuration Snapshots

### Connection String (Production)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Port=3306;Database=MedicalApp;Uid=root;Pwd=yourpassword;"
  }
}
```

### Dependency Injection Setup
```csharp
// Program.cs
builder.Services.AddDbContext<MedicalDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
builder.Services.AddScoped<IPatientService, DatabasePatientService>();
```

---

**Snapshot captured on**: September 8, 2025  
**Application Status**: Fully Functional ✅  
**Database Status**: Connected & Operational ✅  
**Test Status**: Manual Testing Passed ✅
