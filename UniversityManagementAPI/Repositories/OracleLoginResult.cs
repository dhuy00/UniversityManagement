public sealed record OracleLoginResult(
    AuthenticatedUser User,
    string ConnectionString);
