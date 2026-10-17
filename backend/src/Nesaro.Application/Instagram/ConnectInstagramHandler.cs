using Nesaro.Application.Abstractions;
using Nesaro.Domain.Entities;

namespace Nesaro.Application.Instagram;

public sealed class InvalidOAuthStateException() : Exception("O link de conexão expirou ou é inválido. Tente conectar de novo pelo app.");

/// <summary>Conecta a conta do Instagram pelo fluxo oficial da Meta (OAuth). A senha nunca passa pela Nesaro.</summary>
public sealed class ConnectInstagramHandler(
    IInstagramClient instagram,
    IOAuthStateService oauthState,
    ITokenStore tokens,
    IInstagramConnectionRepository connections,
    IClock clock)
{
    /// <summary>Passo 1: o app pede a URL e abre no navegador.</summary>
    public string Start(string ownerUid) => instagram.BuildAuthorizeUrl(oauthState.Create(ownerUid));

    /// <summary>Passo 2: a Meta devolve o código para o callback; trocamos por um token de longa duração.</summary>
    public async Task<InstagramConnection> CompleteAsync(string code, string state, CancellationToken cancellationToken)
    {
        var ownerUid = oauthState.ReadOwnerUid(state) ?? throw new InvalidOAuthStateException();

        var shortLived = await instagram.ExchangeCodeAsync(code, cancellationToken);
        var longLived = await instagram.ExchangeForLongLivedAsync(shortLived.AccessToken, cancellationToken);
        var profile = await instagram.GetProfileAsync(longLived.AccessToken, cancellationToken);

        await instagram.SubscribeToCommentsAsync(longLived.AccessToken, cancellationToken);

        var now = clock.UtcNow;
        await tokens.SaveAsync(
            new StoredToken(ownerUid, profile.UserId, longLived.AccessToken, now.AddSeconds(longLived.ExpiresInSeconds)),
            cancellationToken);

        var connection = new InstagramConnection(ownerUid, profile.UserId, profile.Username, now);
        await connections.SaveAsync(connection, cancellationToken);

        return connection;
    }
}
