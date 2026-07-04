using Microsoft.Extensions.Options;

public sealed class AuthService : IAuthService
{
    private readonly IAuthRepository _authRepository;
    private readonly IOracleSessionStore _sessionStore;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly JwtOptions _jwtOptions;

    public AuthService(
        IAuthRepository authRepository,
        IOracleSessionStore sessionStore,
        IJwtTokenService jwtTokenService,
        IOptions<JwtOptions> jwtOptions)
    {
        _authRepository = authRepository;
        _sessionStore = sessionStore;
        _jwtTokenService = jwtTokenService;
        _jwtOptions = jwtOptions.Value;
    }

    public async Task<LoginResponse?> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken)
    {
        var oracleLogin = await _authRepository.AuthenticateAsync(
            request.Username,
            request.Password,
            cancellationToken);

        if (oracleLogin is null)
        {
            return null;
        }

        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(
            _jwtOptions.ExpirationMinutes);
        var sessionId = _sessionStore.Create(
            oracleLogin.ConnectionString,
            expiresAt);
        var accessToken = _jwtTokenService.CreateToken(
            sessionId,
            oracleLogin.User,
            expiresAt);

        return new LoginResponse(accessToken, expiresAt, oracleLogin.User);
    }

    public void Logout(string sessionId)
    {
        _sessionStore.Remove(sessionId);
    }
}
