using MedicalWebApp.Services;
using MedicalWebApp.Data;
using Microsoft.EntityFrameworkCore;

Console.WriteLine("🚀 Medical Web App Starting...");

var builder = WebApplication.CreateBuilder(args);

// Configure port for deployment platforms
var portEnv = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrEmpty(portEnv) && int.TryParse(portEnv, out int port))
{
    Console.WriteLine($"✅ Configuring for deployment port: {port}");
    builder.WebHost.UseUrls($"http://*:{port}");
}

// Add services to the container.
builder.Services.AddRazorPages();

// Configure Entity Framework with simplified logic
builder.Services.AddDbContext<MedicalDbContext>(options =>
{
    var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    
    if (!string.IsNullOrEmpty(databaseUrl))
    {
        // Production: Use DATABASE_URL (PostgreSQL)
        Console.WriteLine("✅ Using DATABASE_URL for production PostgreSQL");
        
        try
        {
            if (Uri.TryCreate(databaseUrl, UriKind.Absolute, out Uri? uri) && 
                (uri.Scheme == "postgresql" || uri.Scheme == "postgres"))
            {
                var port = uri.Port == -1 ? 5432 : uri.Port;
                var host = uri.Host;
                var database = uri.AbsolutePath.TrimStart('/');
                var userInfo = uri.UserInfo.Split(':');
                
                if (userInfo.Length == 2 && !string.IsNullOrEmpty(database))
                {
                    var connectionString = $"Host={host};Port={port};Database={database};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true;";
                    options.UseNpgsql(connectionString);
                    Console.WriteLine("✅ PostgreSQL configured successfully");
                }
                else
                {
                    throw new ArgumentException("Invalid DATABASE_URL format");
                }
            }
            else
            {
                throw new ArgumentException("Invalid DATABASE_URL format");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Failed to configure DATABASE_URL: {ex.Message}");
            throw;
        }
    }
    else if (builder.Environment.IsProduction())
    {
        // Production fallback to appsettings PostgreSQL
        var connectionString = builder.Configuration.GetConnectionString("PostgreSQLConnection");
        if (!string.IsNullOrEmpty(connectionString))
        {
            Console.WriteLine("⚠️ Using fallback PostgreSQL connection from appsettings");
            options.UseNpgsql(connectionString);
        }
        else
        {
            throw new InvalidOperationException("No production database connection found");
        }
    }
    else
    {
        // Development: Use SQLite by default
        var sqliteConnection = builder.Configuration.GetConnectionString("SqliteConnection") ?? "Data Source=MedicalApp.db";
        Console.WriteLine("🔧 Development: Using SQLite database");
        options.UseSqlite(sqliteConnection);
    }
});

// Register patient service
builder.Services.AddScoped<IPatientService, DatabasePatientService>();

var app = builder.Build();

// Initialize database
try
{
    Console.WriteLine("🗄️ Initializing database...");
    using (var scope = app.Services.CreateScope())
    {
        var context = scope.ServiceProvider.GetRequiredService<MedicalDbContext>();
        
        if (app.Environment.IsProduction())
        {
            // Production: Run migrations
            Console.WriteLine("🗄️ Applying migrations for production...");
            await context.Database.MigrateAsync();
        }
        else
        {
            // Development: Ensure database is created
            Console.WriteLine("🗄️ Ensuring database exists for development...");
            await context.Database.EnsureCreatedAsync();
        }
        
        Console.WriteLine("✅ Database initialized successfully!");
    }
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Database initialization failed: {ex.Message}");
    // In development, continue anyway to avoid breaking the learning experience
    if (app.Environment.IsProduction())
    {
        throw;
    }
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

Console.WriteLine("🚀 Medical Web App ready!");
app.Run();
