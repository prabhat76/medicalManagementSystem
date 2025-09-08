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

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

app.Run();
