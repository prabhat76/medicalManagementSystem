using MedicalWebApp.Services;
using MedicalWebApp.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

// Configure Entity Framework with multiple database providers
builder.Services.AddDbContext<MedicalDbContext>(options =>
{
    // Try to get DATABASE_URL from environment (GitHub/Neon integration)
    var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    var connectionString = databaseUrl ?? builder.Configuration.GetConnectionString("DefaultConnection");
    
    // Check if we're in production or if PostgreSQL connection is specified
    if (builder.Environment.IsProduction() || 
        (!string.IsNullOrEmpty(connectionString) && connectionString.Contains("neon.tech")) || 
        (!string.IsNullOrEmpty(connectionString) && connectionString.Contains("postgres://")) ||
        !string.IsNullOrEmpty(databaseUrl))
    {
        // Parse DATABASE_URL format if needed (postgres://user:pass@host:port/db)
        if (!string.IsNullOrEmpty(connectionString) && connectionString.StartsWith("postgres://"))
        {
            var uri = new Uri(connectionString);
            var npgsqlConnectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.Trim('/')};Username={uri.UserInfo.Split(':')[0]};Password={uri.UserInfo.Split(':')[1]};SSL Mode=Require;Trust Server Certificate=true;";
            options.UseNpgsql(npgsqlConnectionString);
        }
        else if (!string.IsNullOrEmpty(connectionString))
        {
            // Use PostgreSQL for production (Neon)
            options.UseNpgsql(connectionString);
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

app.UseHttpsRedirection();

app.UseStaticFiles(); // .NET 8.0 compatible static files

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages(); // .NET 8.0 compatible Razor Pages mapping

app.Run();
