using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Nesaro.Infrastructure.Options;

namespace Nesaro.Api.Security;

/// <summary>
/// Confere o cabeçalho X-Hub-Signature-256: só a Meta conhece o App Secret,
/// então qualquer chamada falsa ao webhook é recusada.
/// </summary>
public sealed class MetaSignatureValidator(IOptions<MetaOptions> options)
{
    private const string Prefix = "sha256=";

    private readonly byte[] _secret = Encoding.UTF8.GetBytes(options.Value.AppSecret);

    public bool IsValid(byte[] body, string? signatureHeader)
    {
        if (string.IsNullOrWhiteSpace(signatureHeader) ||
            !signatureHeader.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var expected = Convert.ToHexStringLower(HMACSHA256.HashData(_secret, body));
        var received = signatureHeader[Prefix.Length..].Trim().ToLowerInvariant();

        return CryptographicOperations.FixedTimeEquals(
            Encoding.ASCII.GetBytes(expected),
            Encoding.ASCII.GetBytes(received));
    }
}
