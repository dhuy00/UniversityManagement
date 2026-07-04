using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

public sealed class JwtTokenService : IJwtTokenService
{
    private readonly JwtOptions _options;
    private readonly JwtSigningKeyProvider _signingKeyProvider;

    public JwtTokenService(
        IOptions<JwtOptions> options,
        JwtSigningKeyProvider signingKeyProvider)
    {
        _options = options.Value;
        _signingKeyProvider = signingKeyProvider;
    }

    public string CreateToken(
        string sessionId,
        AuthenticatedUser user,
        DateTimeOffset expiresAt)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Username),
            new(ClaimTypes.Name, user.Username),
            new(ClaimTypes.Role, user.RoleCode),
            new("sid", sessionId),
            new("identity_type", user.IdentityType)
        };

        if (user.StaffId is not null)
        {
            claims.Add(new Claim("staff_id", user.StaffId));
        }

        if (user.StudentId is not null)
        {
            claims.Add(new Claim("student_id", user.StudentId));
        }

        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(_signingKeyProvider.Key),
            SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: expiresAt.UtcDateTime,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
