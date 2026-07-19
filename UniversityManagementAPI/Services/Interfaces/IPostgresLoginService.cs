public interface IPostgresLoginService
{
    Task<PostgresLoginResult?> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken);
}
