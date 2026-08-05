using System.Security.Claims;
using Microsoft.Extensions.Options;

public sealed class PostgresLoginService : IPostgresLoginService
{
    private readonly IPostgresAuthRepository _authRepository;
    private readonly IPasswordVerifier _passwordVerifier;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly int _expirationMinutes;

    public PostgresLoginService(
        IPostgresAuthRepository authRepository,
        IPasswordVerifier passwordVerifier,
        IJwtTokenService jwtTokenService,
        IOptions<JwtOptions> jwtOptions)
    {
        _authRepository = authRepository;
        _passwordVerifier = passwordVerifier;
        _jwtTokenService = jwtTokenService;
        _expirationMinutes = jwtOptions.Value.ExpirationMinutes;
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

        if (!UniversityIdentityValidator.IsTrusted(user))
        {
            return null;
        }

        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(_expirationMinutes);
        var token = _jwtTokenService.CreateToken(
            candidate.UserId.ToString(),
            user,
            expiresAt,
            new[] { new Claim(HttpContextPostgresUser.UserIdClaim, candidate.UserId.ToString()) });

        return new PostgresLoginResult(token, expiresAt, user);
    }

    private const string DummyPasswordHash =
        "$2a$12$R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW";
}
