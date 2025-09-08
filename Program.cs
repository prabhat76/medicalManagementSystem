using MedicalWebApp.Services;
using MedicalWebApp.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// 🚀 Configure for Railway deployment
builder.WebHost.ConfigureKestrel(options =>
{
    var port = Environment.GetEnvironmentVariable("PORT");
    if (!string.IsNullOrEmpty(port) && int.TryParse(port, out int portNumber))
    {
        options.ListenAnyIP(portNumber);
    }
});

// Add services to the container.
builder.Services.AddRazorPages();

// Configure Entity Framework with multiple database providers
builder.Services.AddDbContext<MedicalDbContext>(options =>
{
    // Try to get DATABASE_URL from environment (Railway/Neon integration)
    var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    var connectionString = databaseUrl ?? builder.Configuration.GetConnectionString("DefaultConnection");
    
    Console.WriteLine($"🔍 DATABASE_URL found: {!string.IsNullOrEmpty(databaseUrl)}");
    Console.WriteLine($"🔍 Connection string (first 30 chars): {connectionString?.Substring(0, Math.Min(30, connectionString?.Length ?? 0))}...");
    
    // Check if we're in production or if PostgreSQL connection is specified
    if (builder.Environment.IsProduction() || 
        (!string.IsNullOrEmpty(connectionString) && connectionString.Contains("neon.tech")) || 
        (!string.IsNullOrEmpty(connectionString) && (connectionString.Contains("postgres://") || connectionString.Contains("postgresql://"))) ||
        !string.IsNullOrEmpty(databaseUrl))
    {
        try
        {
            // Parse DATABASE_URL format if needed (postgres:// or postgresql://user:pass@host:port/db)
            if (!string.IsNullOrEmpty(connectionString) && 
                (connectionString.StartsWith("postgres://") || connectionString.StartsWith("postgresql://")))
            {
                var uri = new Uri(connectionString);
                var database = uri.AbsolutePath.Trim('/');
                var userInfo = uri.UserInfo.Split(':');
                
                if (userInfo.Length != 2 || string.IsNullOrEmpty(database))
                {
                    throw new ArgumentException("Invalid DATABASE_URL format");
                }
                
                var npgsqlConnectionString = $"Host={uri.Host};Port={uri.Port};Database={database};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true;";
                Console.WriteLine($"✅ Using parsed PostgreSQL connection string");
                options.UseNpgsql(npgsqlConnectionString);
            }
            else if (!string.IsNullOrEmpty(connectionString))
            {
                // Use PostgreSQL connection string as-is (already in Npgsql format)
                Console.WriteLine($"✅ Using direct PostgreSQL connection string");
                options.UseNpgsql(connectionString);
            }
            else
            {
                // Fallback to PostgreSQL connection from appsettings in production
                var fallbackConnection = builder.Configuration.GetConnectionString("PostgreSQLConnection");
                if (!string.IsNullOrEmpty(fallbackConnection))
                {
                    Console.WriteLine($"⚠️ Using fallback PostgreSQL connection from appsettings");
                    options.UseNpgsql(fallbackConnection);
                }
                else
                {
                    throw new ArgumentException("No valid database connection string found - neither DATABASE_URL nor PostgreSQLConnection available");
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
