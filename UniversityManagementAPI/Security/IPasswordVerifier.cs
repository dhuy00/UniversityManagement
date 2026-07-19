public interface IPasswordVerifier
{
    bool Verify(string? password, string? passwordHash);
}
