using Microsoft.AspNetCore.Http;
using System.Security.Authentication;
using System.Security.Claims;

public sealed class HttpContextPostgresUserTests
{
    [Fact]
    public void GetRequiredUserId_ReturnsServerValidatedClaim()
    {
        var accessor = CreateAccessor(new Claim(HttpContextPostgresUser.UserIdClaim, "42"));
        var user = new HttpContextPostgresUser(accessor);

        Assert.Equal(42, user.GetRequiredUserId());
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("0")]
    [InlineData("-1")]
    [InlineData("not-a-number")]
    public void GetRequiredUserId_RejectsMissingOrInvalidClaim(string? value)
    {
        var claim = value is null
            ? null
            : new Claim(HttpContextPostgresUser.UserIdClaim, value);
        var accessor = CreateAccessor(claim);
        var user = new HttpContextPostgresUser(accessor);

        Assert.Throws<AuthenticationException>(() => user.GetRequiredUserId());
    }

    [Fact]
    public void GetRequiredUserId_RejectsUnauthenticatedPrincipal()
    {
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [new Claim(HttpContextPostgresUser.UserIdClaim, "42")]))
        };
        var user = new HttpContextPostgresUser(
            new HttpContextAccessor { HttpContext = context });

        Assert.Throws<AuthenticationException>(() => user.GetRequiredUserId());
    }

    private static HttpContextAccessor CreateAccessor(Claim? userIdClaim)
    {
        var claims = userIdClaim is null ? [] : new[] { userIdClaim };
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(claims, "Test"))
        };
        return new HttpContextAccessor { HttpContext = context };
    }
}
