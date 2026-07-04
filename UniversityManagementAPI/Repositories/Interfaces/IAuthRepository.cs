public interface IAuthRepository
{
    Task<OracleLoginResult?> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken);
}
