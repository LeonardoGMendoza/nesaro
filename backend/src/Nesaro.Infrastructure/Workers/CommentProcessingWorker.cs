using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Nesaro.Application.Abstractions;
using Nesaro.Application.Comments;

namespace Nesaro.Infrastructure.Workers;

/// <summary>
/// Lê a fila e processa cada comentário.
/// O worker é Singleton, então NÃO recebe o handler (Scoped) no construtor:
/// cria um escopo novo por item com IServiceScopeFactory (evita dependência cativa).
/// </summary>
internal sealed class CommentProcessingWorker(
    ICommentQueue queue,
    IServiceScopeFactory scopeFactory,
    ILogger<CommentProcessingWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await foreach (var comment in queue.ReadAllAsync(stoppingToken))
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var handler = scope.ServiceProvider.GetRequiredService<ProcessCommentHandler>();
                await handler.HandleAsync(comment, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                // Um comentário com erro nunca derruba a fila inteira.
                logger.LogError(ex, "Erro ao processar o comentário {CommentId}.", comment.CommentId);
            }
        }
    }
}
