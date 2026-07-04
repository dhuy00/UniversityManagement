using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

public static class AuthenticationServiceExtensions
{
    public static IServiceCollection AddUniversityAuthentication(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        var jwtOptions = configuration
            .GetSection(JwtOptions.SectionName)
            .Get<JwtOptions>()
            ?? throw new InvalidOperationException("Jwt configuration is required.");

        if (string.IsNullOrWhiteSpace(jwtOptions.Issuer))
        {
            throw new InvalidOperationException("Jwt:Issuer is required.");
        }

        if (string.IsNullOrWhiteSpace(jwtOptions.Audience))
        {
            throw new InvalidOperationException("Jwt:Audience is required.");
        }

        if (jwtOptions.ExpirationMinutes <= 0)
        {
            throw new InvalidOperationException("Jwt:ExpirationMinutes must be greater than zero.");
        }

        var keyIsValid = !string.IsNullOrWhiteSpace(jwtOptions.Key) &&
            Encoding.UTF8.GetByteCount(jwtOptions.Key) >= 32;

        if (!environment.IsDevelopment() && !keyIsValid)
        {
            throw new InvalidOperationException(
                "Jwt:Key must contain at least 32 bytes outside Development.");
        }

        var signingKeyProvider = new JwtSigningKeyProvider(
            keyIsValid ? jwtOptions.Key : null);

        services.Configure<JwtOptions>(
            configuration.GetSection(JwtOptions.SectionName));
        services.AddHttpContextAccessor();
        services.AddDataProtection();
        services.AddSingleton(signingKeyProvider);
        services.AddSingleton<IOracleSessionStore, OracleSessionStore>();
        services.AddSingleton<IJwtTokenService, JwtTokenService>();
        services.AddScoped<IAuthRepository, AuthRepository>();
        services.AddScoped<IAuthService, AuthService>();

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = jwtOptions.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwtOptions.Audience,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(signingKeyProvider.Key),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromSeconds(30)
                };
                options.Events = new JwtBearerEvents
                {
                    OnTokenValidated = context =>
                    {
                        var sessionId = context.Principal?.FindFirst("sid")?.Value;
                        var sessions = context.HttpContext.RequestServices
                            .GetRequiredService<IOracleSessionStore>();

                        if (string.IsNullOrWhiteSpace(sessionId) ||
                            !sessions.IsActive(sessionId))
                        {
                            context.Fail("The Oracle session is unavailable or expired.");
                        }

                        return Task.CompletedTask;
                    }
                };
            });

        services.AddAuthorization();
        return services;
    }
}
