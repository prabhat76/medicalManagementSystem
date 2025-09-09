using MedicalWebApp.Services;
using MedicalWebApp.Data;
using Microsoft.EntityFrameworkCore;

Console.WriteLine("🚀 Medical Web App Starting...");

var builder = WebApplication.CreateBuilder(args);

// 🚀 Simple Railway port configuration
var portEnv = Environment.GetEnvironmentVariable("PORT");
Console.WriteLine($"🔍 PORT environment variable: '{portEnv ?? "null"}'");

if (!string.IsNullOrEmpty(portEnv) && int.TryParse(portEnv, out int railwayPort))
{
    Console.WriteLine($"✅ Configuring for Railway port: {railwayPort}");
    builder.WebHost.UseUrls($"http://*:{railwayPort}");
}
else
{
    Console.WriteLine("⚠️ No valid PORT found, using default configuration");
}

// Add services to the container.
builder.Services.AddRazorPages();

// 🗄️ Configure Entity Framework with detailed debugging
builder.Services.AddDbContext<MedicalDbContext>(options =>
{
    var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    Console.WriteLine($"🔍 DATABASE_URL found: {!string.IsNullOrEmpty(databaseUrl)}");
    
    if (!string.IsNullOrEmpty(databaseUrl))
    {
        Console.WriteLine($"🔍 DATABASE_URL (first 50 chars): {databaseUrl.Substring(0, Math.Min(50, databaseUrl.Length))}...");
        
        try
        {
            // Direct PostgreSQL connection for Railway
            Console.WriteLine("✅ Using DATABASE_URL for PostgreSQL connection");
            options.UseNpgsql(databaseUrl);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Failed to configure DATABASE_URL: {ex.Message}");
            throw;
        }
    }
    else
    {
        // Fallback to appsettings
        var fallbackConnection = builder.Configuration.GetConnectionString("PostgreSQLConnection");
        Console.WriteLine($"🔍 Fallback connection found: {!string.IsNullOrEmpty(fallbackConnection)}");
        
        if (!string.IsNullOrEmpty(fallbackConnection))
        {
            Console.WriteLine("⚠️ Using fallback PostgreSQL connection from appsettings");
            options.UseNpgsql(fallbackConnection);
        }
        else
        {
            Console.WriteLine("❌ No database connection available!");
            throw new InvalidOperationException("No database connection string found");
        }
    }
});

// Register our patient service for dependency injection
builder.Services.AddScoped<IPatientService, DatabasePatientService>();

var app = builder.Build();

// 🗄️ Ensure database is created and migrations are applied
try
{
    Console.WriteLine("🗄️ Starting database initialization...");
    using (var scope = app.Services.CreateScope())
    {
        var context = scope.ServiceProvider.GetRequiredService<MedicalDbContext>();
        
        // Test database connection first
        Console.WriteLine("🔍 Testing database connection...");
        await context.Database.CanConnectAsync();
        Console.WriteLine("✅ Database connection successful!");
        
        // Apply migrations in production
        if (app.Environment.IsProduction())
        {
            Console.WriteLine("🗄️ Applying database migrations in production...");
            await context.Database.MigrateAsync();
            Console.WriteLine("✅ Database migrations completed successfully!");
        }
        else
        {
            // For development, just ensure database is created
            await context.Database.EnsureCreatedAsync();
            Console.WriteLine("✅ Database ensured for development");
        }
    }
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Database initialization error: {ex.Message}");
    Console.WriteLine($"❌ Stack trace: {ex.StackTrace}");
    // Continue anyway - don't crash the app for database issues in startup
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();
app.MapRazorPages();

Console.WriteLine("🚀 Medical Web App configured successfully!");
app.Run();
