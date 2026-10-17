using System.Security.Cryptography;
using Google.Cloud.Firestore;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Extensions.Logging;
using Nesaro.Application.Abstractions;

namespace Nesaro.Infrastructure.Firestore;

/// <summary>
/// Guarda o token do Instagram criptografado com ASP.NET Data Protection.
/// Mesmo quem tiver acesso ao Firestore não consegue usar o token sem as chaves do servidor.
/// </summary>
internal sealed class FirestoreTokenStore : ITokenStore
{
    private readonly FirestoreDb _db;
    private readonly IDataProtector _protector;
    private readonly ILogger<FirestoreTokenStore> _logger;

    public FirestoreTokenStore(FirestoreDb db, IDataProtectionProvider protectionProvider, ILogger<FirestoreTokenStore> logger)
    {
        _db = db;
        _protector = protectionProvider.CreateProtector("Nesaro.InstagramTokens.v1");
        _logger = logger;
    }

    public Task SaveAsync(StoredToken token, CancellationToken cancellationToken) =>
        FirestorePaths.IgTokens(_db).Document(token.OwnerUid).SetAsync(
            new Dictionary<string, object>
            {
                ["igAccountId"] = token.IgAccountId,
                ["token"] = _protector.Protect(token.AccessToken),
                ["expiresAt"] = Timestamp.FromDateTimeOffset(token.ExpiresAt),
                ["updatedAt"] = Timestamp.GetCurrentTimestamp(),
            },
            cancellationToken: cancellationToken);

    public async Task<StoredToken?> GetAsync(string ownerUid, CancellationToken cancellationToken)
    {
        var snapshot = await FirestorePaths.IgTokens(_db).Document(ownerUid).GetSnapshotAsync(cancellationToken);
        return snapshot.Exists ? Map(snapshot) : null;
    }

    public Task DeleteAsync(string ownerUid, CancellationToken cancellationToken) =>
        FirestorePaths.IgTokens(_db).Document(ownerUid).DeleteAsync(cancellationToken: cancellationToken);

    public async Task<IReadOnlyList<StoredToken>> ListExpiringAsync(DateTimeOffset before, CancellationToken cancellationToken)
    {
        var snapshot = await FirestorePaths.IgTokens(_db)
            .WhereLessThan("expiresAt", Timestamp.FromDateTimeOffset(before))
            .GetSnapshotAsync(cancellationToken);

        return snapshot.Documents
            .Select(Map)
            .OfType<StoredToken>()
            .ToList();
    }

    private StoredToken? Map(DocumentSnapshot snapshot)
    {
        if (!snapshot.TryGetValue<string>("token", out var protectedToken) ||
            !snapshot.TryGetValue<string>("igAccountId", out var igAccountId) ||
            !snapshot.TryGetValue<Timestamp>("expiresAt", out var expiresAt))
        {
            return null;
        }

        try
        {
            return new StoredToken(snapshot.Id, igAccountId, _protector.Unprotect(protectedToken), expiresAt.ToDateTimeOffset());
        }
        catch (CryptographicException ex)
        {
            // Acontece se a pasta de chaves do servidor for perdida. O cliente precisa reconectar.
            _logger.LogError(ex, "Não foi possível descriptografar o token do cliente {OwnerUid}.", snapshot.Id);
            return null;
        }
    }
}
