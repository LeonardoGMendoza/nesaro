using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Nesaro.Application.Instagram;

namespace Nesaro.Infrastructure.Workers;

/// <summary>Duas vezes por dia, renova os tokens do Instagram que estão perto de vencer.</summary>
internal sealed class TokenRefreshWorker(
    IServiceScopeFactory scopeFactory,
    ILogger<TokenRefreshWorker> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(12);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);

        do
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var handler = scope.ServiceProvider.GetRequiredService<RefreshInstagramTokensHandler>();
                await handler.HandleAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Erro na rotina de renovação de tokens.");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
