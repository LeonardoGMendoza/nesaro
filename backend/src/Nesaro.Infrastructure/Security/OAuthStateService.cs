using System.Security.Cryptography;
using Microsoft.AspNetCore.DataProtection;
using Nesaro.Application.Abstractions;

namespace Nesaro.Infrastructure.Security;

/// <summary>
/// O "state" é o UID do cliente criptografado e assinado, válido por 15 minutos.
/// Impede que alguém ligue a própria conta do Instagram ao cadastro de outra pessoa.
/// </summary>
internal sealed class OAuthStateService : IOAuthStateService
{
    private static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(15);

    private readonly ITimeLimitedDataProtector _protector;

    public OAuthStateService(IDataProtectionProvider protectionProvider)
    {
        _protector = protectionProvider.CreateProtector("Nesaro.OAuthState.v1").ToTimeLimitedDataProtector();
    }

    public string Create(string ownerUid) =>
        _protector.Protect($"{ownerUid}|{Guid.NewGuid():N}", Lifetime);

    public string? ReadOwnerUid(string state)
    {
        try
        {
            var raw = _protector.Unprotect(state);
            var separator = raw.IndexOf('|');
            return separator > 0 ? raw[..separator] : null;
        }
        catch (CryptographicException)
        {
            return null;
        }
    }
}
