public sealed class PostgresAuthRepositoryIntegrationTests
{
    [Fact]
    public async Task FindsActiveUserAndMapsAuthenticationFields()
    {
        var settings = AuthenticationIntegrationSettings.TryLoad();
        if (settings is null)
        {
            return;
        }

        await using var source = new PostgresAuthenticationDataSource(
            settings.ConnectionString);
        var repository = new PostgresAuthRepository(source);

        var candidate = await repository.FindActiveByUsernameAsync(
            $"  {settings.ActiveUsername.ToLowerInvariant()}  ",
            CancellationToken.None);

        Assert.NotNull(candidate);
        Assert.True(candidate.UserId > 0);
        Assert.Equal(
            settings.ActiveUsername,
            candidate.Username,
            ignoreCase: true);
        Assert.False(string.IsNullOrWhiteSpace(candidate.PasswordHash));
        Assert.NotEmpty(candidate.RoleCodes);
        Assert.Contains(candidate.IdentityType, new[] { "STAFF", "STUDENT" });
        Assert.False(string.IsNullOrWhiteSpace(candidate.CampusId));
    }

    [Fact]
    public async Task ReturnsNullForUnknownAndInactiveUsers()
    {
        var settings = AuthenticationIntegrationSettings.TryLoad();
        if (settings is null)
        {
            return;
        }

        await using var source = new PostgresAuthenticationDataSource(
            settings.ConnectionString);
        var repository = new PostgresAuthRepository(source);

        Assert.Null(await repository.FindActiveByUsernameAsync(
            $"MISSING_{Guid.NewGuid():N}",
            CancellationToken.None));

        if (settings.InactiveUsername is not null)
        {
            Assert.Null(await repository.FindActiveByUsernameAsync(
                settings.InactiveUsername,
                CancellationToken.None));
        }
    }

    [Fact]
    public async Task PreservesMissingRoleAndMalformedIdentityForServiceValidation()
    {
        var settings = AuthenticationIntegrationSettings.TryLoad();
        if (settings?.MissingRoleUsername is null ||
            settings.MalformedIdentityUsername is null)
        {
            return;
        }

        await using var source = new PostgresAuthenticationDataSource(
            settings.ConnectionString);
        var repository = new PostgresAuthRepository(source);

        var missingRole = await repository.FindActiveByUsernameAsync(
            settings.MissingRoleUsername,
            CancellationToken.None);
        Assert.NotNull(missingRole);
        Assert.Empty(missingRole.RoleCodes);

        var malformedIdentity = await repository.FindActiveByUsernameAsync(
            settings.MalformedIdentityUsername,
            CancellationToken.None);
        Assert.NotNull(malformedIdentity);
        Assert.Null(malformedIdentity.IdentityType);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public async Task RejectsMissingUsername(string? username)
    {
        await using var source = new PostgresAuthenticationDataSource(
            "Host=localhost;Database=unused;Username=unused;Password=unused");
        var repository = new PostgresAuthRepository(source);

        await Assert.ThrowsAnyAsync<ArgumentException>(() =>
            repository.FindActiveByUsernameAsync(
                username!,
                CancellationToken.None));
    }

    private sealed record AuthenticationIntegrationSettings(
        string ConnectionString,
        string ActiveUsername,
        string? InactiveUsername,
        string? MissingRoleUsername,
        string? MalformedIdentityUsername)
    {
        public static AuthenticationIntegrationSettings? TryLoad()
        {
            var connectionString = Environment.GetEnvironmentVariable(
                "POSTGRES_AUTH_INTEGRATION_CONNECTION_STRING");
            var activeUsername = Environment.GetEnvironmentVariable(
                "POSTGRES_AUTH_TEST_ACTIVE_USERNAME");

            return string.IsNullOrWhiteSpace(connectionString) ||
                string.IsNullOrWhiteSpace(activeUsername)
                    ? null
                    : new AuthenticationIntegrationSettings(
                        connectionString,
                        activeUsername,
                        Environment.GetEnvironmentVariable(
                            "POSTGRES_AUTH_TEST_INACTIVE_USERNAME"),
                        Environment.GetEnvironmentVariable(
                            "POSTGRES_AUTH_TEST_MISSING_ROLE_USERNAME"),
                        Environment.GetEnvironmentVariable(
                            "POSTGRES_AUTH_TEST_MALFORMED_IDENTITY_USERNAME"));
        }
    }
}
