using System.Security.Cryptography;
using System.Text;

public sealed class JwtSigningKeyProvider
{
    public JwtSigningKeyProvider(string? configuredKey = null)
    {
        Key = string.IsNullOrWhiteSpace(configuredKey)
            ? RandomNumberGenerator.GetBytes(32)
            : Encoding.UTF8.GetBytes(configuredKey);

        if (Key.Length < 32)
        {
            throw new InvalidOperationException("Jwt:Key must contain at least 32 bytes.");
        }
    }

    public byte[] Key { get; }
}
