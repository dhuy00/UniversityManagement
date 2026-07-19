public sealed class PostgresRequestTransactionMiddleware
{
    private readonly RequestDelegate _next;

    public PostgresRequestTransactionMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(
        HttpContext context,
        IPostgresRequestTransaction requestTransaction)
    {
        var hasPostgresIdentity = context.User.Identity?.IsAuthenticated == true &&
            context.User.HasClaim(claim =>
                claim.Type == HttpContextPostgresUser.UserIdClaim);

        if (!hasPostgresIdentity)
        {
            await _next(context);
            return;
        }

        await requestTransaction.InitializeAsync(context.RequestAborted);
        await _next(context);
        await requestTransaction.CommitAsync(context.RequestAborted);
    }
}

public static class PostgresRequestTransactionMiddlewareExtensions
{
    public static IApplicationBuilder UsePostgresRequestTransaction(
        this IApplicationBuilder app) =>
        app.UseMiddleware<PostgresRequestTransactionMiddleware>();
}
