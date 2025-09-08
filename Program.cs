using MedicalWebApp.Services;
using MedicalWebApp.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// 🚀 Configure for Railway deployment
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
Console.WriteLine($"🚀 Railway PORT environment variable: {Environment.GetEnvironmentVariable("PORT") ?? "Not Set"}");
Console.WriteLine($"🚀 Using port: {port}");

builder.WebHost.ConfigureKestrel(options =>
{
    if (int.TryParse(port, out int portNumber))
    {
        options.ListenAnyIP(portNumber);
        Console.WriteLine($"🚀 Kestrel configured to listen on port {portNumber}");
    }
});

// Ensure ASPNETCORE_URLS is not conflicting
Environment.SetEnvironmentVariable("ASPNETCORE_URLS", $"http://+:{port}");

// Add services to the container.
builder.Services.AddRazorPages();

// Configure Entity Framework with multiple database providers
builder.Services.AddDbContext<MedicalDbContext>(options =>
{
    // Try to get DATABASE_URL from environment (Railway/Neon integration)
    var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    var connectionString = databaseUrl ?? builder.Configuration.GetConnectionString("DefaultConnection");
    
    // Simple debug output that will appear in Railway logs
    Console.WriteLine($"🔍 Environment: {builder.Environment.EnvironmentName}");
    Console.WriteLine($"🔍 DATABASE_URL found: {!string.IsNullOrEmpty(databaseUrl)}");
    Console.WriteLine($"🔍 Connection string length: {connectionString?.Length ?? 0}");
    Console.WriteLine($"🔍 Connection string starts with: {(string.IsNullOrEmpty(connectionString) ? "NULL" : connectionString.Substring(0, Math.Min(20, connectionString.Length)))}");
    
    // Ensure we have a valid connection string
    if (string.IsNullOrEmpty(connectionString))
    {
        // Try fallback connections
        connectionString = builder.Configuration.GetConnectionString("PostgreSQLConnection") 
                        ?? builder.Configuration.GetConnectionString("SqliteConnection");
        Console.WriteLine("⚠️ Using fallback connection string");
    }
    
    if (string.IsNullOrEmpty(connectionString))
    {
        throw new InvalidOperationException("No database connection string found. Please set DATABASE_URL environment variable or configure connection strings in appsettings.json");
    }
    
    // Check if we're in production or if PostgreSQL connection is specified
    if (builder.Environment.IsProduction() || 
        connectionString.Contains("neon.tech") || 
        connectionString.Contains("postgres://") || 
        connectionString.Contains("postgresql://") ||
        !string.IsNullOrEmpty(databaseUrl))
    {
        try
        {
            // Parse DATABASE_URL format if needed (postgres:// or postgresql://user:pass@host:port/db)
            if (connectionString.StartsWith("postgres://") || connectionString.StartsWith("postgresql://"))
            {
                var uri = new Uri(connectionString);
                var database = uri.AbsolutePath.Trim('/');
                var userInfo = uri.UserInfo.Split(':');
                
                if (userInfo.Length != 2 || string.IsNullOrEmpty(database))
                {
                    throw new ArgumentException($"Invalid DATABASE_URL format. Expected format: postgresql://user:password@host:port/database");
                }
                
                var npgsqlConnectionString = $"Host={uri.Host};Port={uri.Port};Database={database};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true;";
                Console.WriteLine("✅ Using parsed PostgreSQL connection string");
                Console.WriteLine($"✅ Parsed connection: Host={uri.Host};Port={uri.Port};Database={database};Username={userInfo[0]};...");
                options.UseNpgsql(npgsqlConnectionString);
            }
            else if (connectionString.Contains("Host=") || connectionString.Contains("Server=") && connectionString.Contains("Database="))
            {
                // Use PostgreSQL connection string as-is (already in Npgsql format)
                Console.WriteLine("✅ Using direct PostgreSQL connection string");
                options.UseNpgsql(connectionString);
            }
            else
            {
                // Fallback to PostgreSQL connection from appsettings in production
                var fallbackConnection = builder.Configuration.GetConnectionString("PostgreSQLConnection");
                if (!string.IsNullOrEmpty(fallbackConnection))
                {
                    Console.WriteLine("⚠️ Using fallback PostgreSQL connection from appsettings");
                    options.UseNpgsql(fallbackConnection);
                }
                else
                {
                    throw new ArgumentException("No valid PostgreSQL connection string found - neither DATABASE_URL nor PostgreSQLConnection available");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Database connection error: {ex.Message}");
            Console.WriteLine($"❌ Connection string: {connectionString}");
            throw;
        }
    }
    else if (!string.IsNullOrEmpty(connectionString) && (connectionString.Contains("mysql") || connectionString.Contains("3306")))
    {
        // Use MySQL for local development
        options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));
    }
    else
    {
        // Fallback to SQLite for local development
        var sqliteConnection = builder.Configuration.GetConnectionString("SqliteConnection");
        options.UseSqlite(sqliteConnection);
    }
});

// Register our patient service for dependency injection
builder.Services.AddScoped<IPatientService, DatabasePatientService>();

var app = builder.Build();

// 🗄️ Ensure database is created and migrations are applied
try
{
    using (var scope = app.Services.CreateScope())
    {
        var context = scope.ServiceProvider.GetRequiredService<MedicalDbContext>();
        
        // Ensure database is created and apply any pending migrations
        if (app.Environment.IsProduction())
        {
            app.Logger.LogInformation("🗄️ Applying database migrations in production...");
            await context.Database.MigrateAsync();
            app.Logger.LogInformation("✅ Database migrations completed successfully!");
        }
        else
        {
            // For development, just ensure database is created
            await context.Database.EnsureCreatedAsync();
        }
    }
}
catch (Exception ex)
{
    app.Logger.LogError(ex, "❌ Error during database initialization: {Message}", ex.Message);
    // Continue anyway - don't crash the app for database issues
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// 🌐 Only use HTTPS redirection in development - Railway handles HTTPS at load balancer
if (app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles(); // .NET 8.0 compatible static files

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages(); // .NET 8.0 compatible Razor Pages mapping

app.Run();
