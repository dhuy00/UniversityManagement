using Npgsql;

public static class PostgresServiceExtensions
{
    public static IServiceCollection AddPostgresRequestInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("PostgreSQL");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:PostgreSQL is required.");
        }

        services.AddSingleton(_ => NpgsqlDataSource.Create(connectionString));
        services.AddSingleton<PostgresAuthenticationDataSource>();
        services.AddSingleton<IPasswordVerifier, BcryptPasswordVerifier>();
        services.AddScoped<IAuthenticatedPostgresUser, HttpContextPostgresUser>();
        services.AddScoped<IPostgresRequestTransaction, PostgresRequestTransaction>();
        services.AddScoped<IPostgresAuthRepository, PostgresAuthRepository>();
        services.AddScoped<IPostgresLoginService, PostgresLoginService>();
        return services;
    }
}
