using Microsoft.Extensions.Logging;
using Nesaro.Application.Abstractions;

namespace Nesaro.Application.Instagram;

/// <summary>
/// Tokens de longa duração do Instagram valem cerca de 60 dias.
/// Este caso de uso renova os que vencem nos próximos 10 dias.
/// </summary>
public sealed class RefreshInstagramTokensHandler(
    ITokenStore tokens,
    IInstagramClient instagram,
    IClock clock,
    ILogger<RefreshInstagramTokensHandler> logger)
{
    private static readonly TimeSpan RefreshWindow = TimeSpan.FromDays(10);

    public async Task HandleAsync(CancellationToken cancellationToken)
    {
        var expiring = await tokens.ListExpiringAsync(clock.UtcNow.Add(RefreshWindow), cancellationToken);

        foreach (var token in expiring)
        {
            try
            {
                var refreshed = await instagram.RefreshAsync(token.AccessToken, cancellationToken);
                await tokens.SaveAsync(
                    token with
                    {
                        AccessToken = refreshed.AccessToken,
                        ExpiresAt = clock.UtcNow.AddSeconds(refreshed.ExpiresInSeconds),
                    },
                    cancellationToken);
            }
            catch (InstagramApiException ex)
            {
                logger.LogWarning(ex, "Não foi possível renovar o token do cliente {OwnerUid}.", token.OwnerUid);
            }
        }
    }
}
