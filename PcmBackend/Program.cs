using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using PcmBackend.Hubs;
using PcmBackend.Services;
using PcmBackend.Data;

var builder = WebApplication.CreateBuilder(args);

// Ensure logging is captured
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

Console.WriteLine("--- PCM BACKEND STARTING (V3 - LOGGING ENHANCED) ---");

// 1. Data Source
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
Console.WriteLine($"Connection String: {connectionString}");

builder.Services.AddDbContext<PcmBackend.Data.ApplicationDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// 2. Identity
builder.Services.AddIdentity<PcmBackend.Data.Entities.Members, Microsoft.AspNetCore.Identity.IdentityRole>()
    .AddEntityFrameworkStores<PcmBackend.Data.ApplicationDbContext>();

// 3. Auth
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"] ?? "FallbackSecretKeyForDebugging_1234567890_LongEnough";
var key = Encoding.UTF8.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"] ?? "https://localhost:7299",
        ValidAudience = jwtSettings["Audience"] ?? "https://localhost:7299",
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// SignalR & Background Services
builder.Services.AddSignalR();
// TEMPORARY: Disabled background services để server start nhanh
// builder.Services.AddHostedService<BookingCleanupService>();
// builder.Services.AddHostedService<ReminderService>();
builder.Services.AddScoped<IVnPayService, VnPayService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(_ => true) // Highly permissive for debug
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials()
              .WithExposedHeaders("*")
              .SetPreflightMaxAge(TimeSpan.FromMinutes(10)); // Cache preflight 10 phút
    });
});

var app = builder.Build();

// Log all requests for debugging
app.Use(async (context, next) => {
    Console.WriteLine($"DEBUG: Received {context.Request.Method} {context.Request.Path}");
    await next();
});

// Enable Swagger always
app.UseSwagger();
app.UseSwaggerUI();

// Removed HttpsRedirection to avoid issues with HTTP-only VPS port
// app.UseHttpsRedirection(); 

app.UseStaticFiles();
app.UseCors("AllowAll");

// ========================================
// FIX CRITICAL: Handle OPTIONS Preflight Requests
// Trình duyệt gửi OPTIONS request trước POST/PUT/DELETE để kiểm tra CORS
// ASP.NET Core không tự động handle OPTIONS, dẫn đến 404 → Connection Error
// Middleware này trả về 200 OK cho MỌI OPTIONS requests
// ========================================
app.Use(async (context, next) =>
{
    if (context.Request.Method == "OPTIONS")
    {
        Console.WriteLine($"PREFLIGHT: Handling OPTIONS {context.Request.Path}");
        context.Response.StatusCode = 200;
        await context.Response.CompleteAsync();
        return;
    }
    await next();
});

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<PcmHub>("/pcmhub");

// Synchronous Migration Check (Blocking startup until DB is ready)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try 
    {
        var context = services.GetRequiredService<PcmBackend.Data.ApplicationDbContext>();
        Console.WriteLine("STARTUP: Database Connection Check...");
        // context.Database.Migrate(); // Disabled: Using existing DB
        Console.WriteLine("STARTUP: Database OK!");
        
        Console.WriteLine("STARTUP: Seeding Database...");
        PcmBackend.Data.DbSeeder.SeedAsync(services).GetAwaiter().GetResult();
        Console.WriteLine("STARTUP: Database Seeding OK!");
    }
    catch (Exception ex)
    {
        Console.WriteLine("STARTUP ERROR: DB Init failed: " + ex.Message);
        if (ex.InnerException != null) Console.WriteLine("INNER: " + ex.InnerException.Message);
    }
}

app.MapGet("/", () => "PCM Backend V3 (Stable) is Running!");

Console.WriteLine("--- READY TO SERVE ---");
app.Run();
