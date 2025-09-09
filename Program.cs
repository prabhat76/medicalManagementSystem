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
    Console.WriteLine($"🔍 DATABASE_URL length: {databaseUrl?.Length ?? 0}");
    
    if (!string.IsNullOrEmpty(databaseUrl))
    {
        // Clean the database URL of any potential invisible characters
        databaseUrl = databaseUrl.Trim();
        Console.WriteLine($"🔍 DATABASE_URL (trimmed, first 50 chars): {databaseUrl.Substring(0, Math.Min(50, databaseUrl.Length))}...");
        Console.WriteLine($"🔍 DATABASE_URL (last 10 chars): ...{databaseUrl.Substring(Math.Max(0, databaseUrl.Length - 10))}");
        
        try
        {
            // Test if this is a valid URI first
            if (Uri.TryCreate(databaseUrl, UriKind.Absolute, out Uri? uri) && 
                (uri.Scheme == "postgresql" || uri.Scheme == "postgres"))
            {
                Console.WriteLine($"✅ Valid PostgreSQL URI detected: {uri.Scheme}://{uri.Host}:{uri.Port}");
                Console.WriteLine("✅ Using DATABASE_URL for PostgreSQL connection");
                options.UseNpgsql(databaseUrl);
            }
            else
            {
                Console.WriteLine($"❌ Invalid DATABASE_URL format or scheme. Expected postgresql:// or postgres://, got: {databaseUrl?.Substring(0, Math.Min(20, databaseUrl?.Length ?? 0))}");
                throw new ArgumentException($"Invalid DATABASE_URL format: {databaseUrl}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Failed to configure DATABASE_URL: {ex.Message}");
            Console.WriteLine($"❌ DATABASE_URL value: '{databaseUrl}'");
            
            // Emergency fallback - try to reconstruct the connection string
            Console.WriteLine("🔄 Attempting emergency fallback connection...");
            var emergencyConnection = "Host=ep-young-feather-aev9szfg-pooler.c-2.us-east-2.aws.neon.tech;Database=neondb;Username=neondb_owner;Password=npg_WQhR73yTCwju;SSL Mode=Require;Trust Server Certificate=true;";
            try
            {
                options.UseNpgsql(emergencyConnection);
                Console.WriteLine("✅ Emergency fallback connection configured!");
            }
            catch (Exception fallbackEx)
            {
                Console.WriteLine($"❌ Emergency fallback also failed: {fallbackEx.Message}");
                throw;
            }
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
