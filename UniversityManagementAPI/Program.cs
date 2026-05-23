using Microsoft.EntityFrameworkCore;
using UniversityManagementAPI.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<ApplicationDbContext>(options => 
    options.UseOracle(
        builder.Configuration.GetConnectionString("OracleDb")
    )
);

builder.Services.AddScoped<IDbConnectionFactory, OracleConnectionFactory>();

// User
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IDbConnectionFactory, OracleConnectionFactory>();

var app = builder.Build();

// Configure pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();