using Microsoft.Extensions.Logging;
using Nesaro.Application.Abstractions;
using Nesaro.Domain.Entities;
using Nesaro.Domain.Enums;
using Nesaro.Domain.ValueObjects;

namespace Nesaro.Application.Comments;

/// <summary>
/// Caso de uso principal do MVP: alguém comentou → achar a automação → mandar a DM → registrar.
/// </summary>
public sealed class ProcessCommentHandler(
    IInstagramConnectionRepository connections,
    IAutomationRepository automations,
    IExecutionRepository executions,
    ITokenStore tokens,
    IInstagramClient instagram,
    IClock clock,
    ILogger<ProcessCommentHandler> logger)
{
    public async Task HandleAsync(IncomingComment comment, CancellationToken cancellationToken)
    {
        if (comment.IsFromAccountOwner)
        {
            return;
        }

        var ownerUid = await connections.FindOwnerUidAsync(comment.IgAccountId, cancellationToken);
        if (ownerUid is null)
        {
            logger.LogWarning("Comentário {CommentId} para conta {IgAccountId} sem cliente vinculado.", comment.CommentId, comment.IgAccountId);
            return;
        }

        var active = await automations.GetActiveAsync(ownerUid, cancellationToken);

        // A Meta permite UMA resposta privada por comentário, então vale a primeira automação que casar.
        var automation = active.FirstOrDefault(a => a.Matches(comment.MediaId, comment.Text));
        if (automation is null)
        {
            return;
        }

        var execution = Execution.Start(comment, automation, clock.UtcNow);
        if (!await executions.TryCreateAsync(ownerUid, execution, cancellationToken))
        {
            logger.LogInformation("Comentário {CommentId} já processado; ignorando duplicata.", comment.CommentId);
            return;
        }

        await automations.IncrementStatAsync(ownerUid, automation.Id, AutomationStat.Matched, cancellationToken);

        var token = await tokens.GetAsync(ownerUid, cancellationToken);
        if (token is null)
        {
            await FailAsync(ownerUid, automation, execution, "Instagram desconectado ou token expirado. Conecte a conta de novo.", cancellationToken);
            return;
        }

        try
        {
            var messageId = await instagram.SendPrivateReplyAsync(
                token.AccessToken,
                comment.IgAccountId,
                comment.CommentId,
                automation.BuildDirectMessage(),
                cancellationToken);

            execution.MarkSent(messageId, clock.UtcNow);
            await executions.UpdateAsync(ownerUid, execution, cancellationToken);
            await automations.IncrementStatAsync(ownerUid, automation.Id, AutomationStat.Sent, cancellationToken);
        }
        catch (InstagramApiException ex)
        {
            logger.LogWarning(ex, "Falha ao enviar DM do comentário {CommentId}.", comment.CommentId);
            await FailAsync(ownerUid, automation, execution, ex.Message, cancellationToken);
            return;
        }

        // A resposta pública é um extra: se falhar, a DM já foi entregue e o registro continua como enviado.
        if (!string.IsNullOrWhiteSpace(automation.PublicReply))
        {
            try
            {
                await instagram.ReplyToCommentAsync(token.AccessToken, comment.CommentId, automation.PublicReply, cancellationToken);
            }
            catch (InstagramApiException ex)
            {
                logger.LogWarning(ex, "Falha na resposta pública do comentário {CommentId}.", comment.CommentId);
            }
        }
    }

    private async Task FailAsync(
        string ownerUid,
        Automation automation,
        Execution execution,
        string error,
        CancellationToken cancellationToken)
    {
        execution.MarkFailed(error, clock.UtcNow);
        await executions.UpdateAsync(ownerUid, execution, cancellationToken);
        await automations.IncrementStatAsync(ownerUid, automation.Id, AutomationStat.Failed, cancellationToken);
    }
}
