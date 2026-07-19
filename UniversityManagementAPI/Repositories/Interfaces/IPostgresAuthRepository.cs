public interface IPostgresAuthRepository
{
    Task<PostgresAuthenticationCandidate?> FindActiveByUsernameAsync(
        string username,
        CancellationToken cancellationToken);
}
