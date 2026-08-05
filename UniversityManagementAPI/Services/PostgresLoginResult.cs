public sealed record PostgresLoginResult(
    string Token,
    DateTimeOffset ExpiresAt,
    AuthenticatedUser User);
