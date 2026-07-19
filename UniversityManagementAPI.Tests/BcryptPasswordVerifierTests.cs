public sealed class BcryptPasswordVerifierTests
{
    private const string Password = "Correct-Horse_Battery#Staple123";
    private static readonly string PasswordHash = BCrypt.Net.BCrypt.HashPassword(
        Password,
        workFactor: 4);

    private readonly BcryptPasswordVerifier _verifier = new();

    [Fact]
    public void Verify_AcceptsMatchingPassword()
    {
        Assert.True(_verifier.Verify(Password, PasswordHash));
    }

    [Fact]
    public void Verify_RejectsWrongPassword()
    {
        Assert.False(_verifier.Verify("wrong-password", PasswordHash));
    }

    [Fact]
    public void Verify_IsCaseSensitive()
    {
        Assert.False(_verifier.Verify(Password.ToLowerInvariant(), PasswordHash));
    }

    [Theory]
    [InlineData(null, null)]
    [InlineData(null, "$2a$12$valid-looking-but-unused-hash-value")]
    [InlineData("password", null)]
    [InlineData("", "$2a$12$valid-looking-but-unused-hash-value")]
    [InlineData("password", "")]
    [InlineData("password", "   ")]
    public void Verify_RejectsMissingPasswordOrHash(
        string? password,
        string? passwordHash)
    {
        Assert.False(_verifier.Verify(password, passwordHash));
    }

    [Theory]
    [InlineData("not-a-bcrypt-hash")]
    [InlineData("$2a$xx$invalid-work-factor")]
    [InlineData("$2a$12$too-short")]
    public void Verify_RejectsMalformedHashWithoutThrowing(string passwordHash)
    {
        Assert.False(_verifier.Verify(Password, passwordHash));
    }
}
