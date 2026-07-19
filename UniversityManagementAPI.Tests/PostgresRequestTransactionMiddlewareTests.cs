using Microsoft.AspNetCore.Http;
using Npgsql;
using System.Security.Claims;

public sealed class PostgresRequestTransactionMiddlewareTests
{
    [Fact]
    public async Task InvokeAsync_InitializesBeforeEndpointAndCommitsAfterward()
    {
        var events = new List<string>();
        var transaction = new RecordingTransaction(events);
        var middleware = new PostgresRequestTransactionMiddleware(_ =>
        {
            events.Add("endpoint");
            return Task.CompletedTask;
        });
        var context = CreateAuthenticatedContext(includePostgresUserId: true);

        await middleware.InvokeAsync(context, transaction);

        Assert.Equal(["initialize", "endpoint", "commit"], events);
    }

    [Fact]
    public async Task InvokeAsync_DoesNotCommitWhenEndpointFails()
    {
        var events = new List<string>();
        var transaction = new RecordingTransaction(events);
        var middleware = new PostgresRequestTransactionMiddleware(_ =>
            throw new InvalidOperationException("Endpoint failed."));
        var context = CreateAuthenticatedContext(includePostgresUserId: true);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => middleware.InvokeAsync(context, transaction));

        Assert.Equal(["initialize"], events);
    }

    [Fact]
    public async Task InvokeAsync_LeavesOracleAuthenticatedRequestUntouched()
    {
        var events = new List<string>();
        var transaction = new RecordingTransaction(events);
        var middleware = new PostgresRequestTransactionMiddleware(_ =>
        {
            events.Add("endpoint");
            return Task.CompletedTask;
        });
        var context = CreateAuthenticatedContext(includePostgresUserId: false);

        await middleware.InvokeAsync(context, transaction);

        Assert.Equal(["endpoint"], events);
    }

    private static DefaultHttpContext CreateAuthenticatedContext(
        bool includePostgresUserId)
    {
        var claims = includePostgresUserId
            ? new[] { new Claim(HttpContextPostgresUser.UserIdClaim, "42") }
            : [];
        return new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(claims, "Test"))
        };
    }

    private sealed class RecordingTransaction(List<string> events)
        : IPostgresRequestTransaction
    {
        public NpgsqlConnection Connection => throw new NotSupportedException();
        public NpgsqlTransaction Transaction => throw new NotSupportedException();
        public long UserId => 42;

        public Task InitializeAsync(CancellationToken cancellationToken = default)
        {
            events.Add("initialize");
            return Task.CompletedTask;
        }

        public Task CommitAsync(CancellationToken cancellationToken = default)
        {
            events.Add("commit");
            return Task.CompletedTask;
        }

        public ValueTask DisposeAsync() => ValueTask.CompletedTask;
    }
}
