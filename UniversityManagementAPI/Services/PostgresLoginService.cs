public sealed class PostgresLoginService : IPostgresLoginService
{
    // Valid BCrypt hash used only to keep the password-verification path active
    // when no active user exists. Its matching plaintext is not used by login.
    private const string DummyPasswordHash =
        "$2a$12$R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW";

    private readonly IPostgresAuthRepository _authRepository;
    private readonly IPasswordVerifier _passwordVerifier;

    public PostgresLoginService(
        IPostgresAuthRepository authRepository,
        IPasswordVerifier passwordVerifier)
    {
        _authRepository = authRepository;
        _passwordVerifier = passwordVerifier;
    }

    public async Task<PostgresLoginResult?> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken)
    {
        var candidate = await _authRepository.FindActiveByUsernameAsync(
            username,
            cancellationToken);
        var passwordMatches = _passwordVerifier.Verify(
            password,
            candidate?.PasswordHash ?? DummyPasswordHash);

        if (candidate is null || !passwordMatches)
        {
            return null;
        }

        var roleCodes = candidate.RoleCodes
            .Distinct(StringComparer.Ordinal)
            .ToArray();
        if (roleCodes.Length != 1 || string.IsNullOrWhiteSpace(candidate.IdentityType))
        {
            return null;
        }

        var user = new AuthenticatedUser(
            candidate.Username,
            candidate.IdentityType,
            roleCodes[0],
            candidate.StaffId,
            candidate.StudentId,
            candidate.UnitId,
            candidate.ProgramId,
            candidate.MajorId,
            candidate.CampusId);

        return UniversityIdentityValidator.IsTrusted(user)
            ? new PostgresLoginResult(candidate.UserId, user)
            : null;
    }
}
