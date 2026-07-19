using BCrypt.Net;
using System.Text.RegularExpressions;

public sealed class BcryptPasswordVerifier : IPasswordVerifier
{
    private static readonly Regex BcryptHashPattern = new(
        @"^\$2[abxy]\$(0[4-9]|[12][0-9]|3[01])\$[./A-Za-z0-9]{53}$",
        RegexOptions.CultureInvariant | RegexOptions.NonBacktracking);

    public bool Verify(string? password, string? passwordHash)
    {
        if (string.IsNullOrEmpty(password) ||
            string.IsNullOrWhiteSpace(passwordHash) ||
            !BcryptHashPattern.IsMatch(passwordHash))
        {
            return false;
        }

        try
        {
            return BCrypt.Net.BCrypt.Verify(password, passwordHash);
        }
        catch (SaltParseException)
        {
            return false;
        }
        catch (ArgumentException)
        {
            return false;
        }
        catch (FormatException)
        {
            return false;
        }
    }
}
