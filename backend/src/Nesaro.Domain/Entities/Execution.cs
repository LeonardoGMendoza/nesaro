using Nesaro.Domain.Enums;
using Nesaro.Domain.ValueObjects;

namespace Nesaro.Domain.Entities;

/// <summary>
/// Registro de uma automação disparada. O Id é o ID do comentário: como a Meta só permite
/// uma resposta privada por comentário, isso garante idempotência (o mesmo evento nunca roda duas vezes).
/// </summary>
public sealed class Execution
{
    private Execution()
    {
    }

    public string Id { get; private set; } = string.Empty;

    public string AutomationId { get; private set; } = string.Empty;

    public string AutomationName { get; private set; } = string.Empty;

    public string CommentId { get; private set; } = string.Empty;

    public string CommentText { get; private set; } = string.Empty;

    public string? CommenterUsername { get; private set; }

    public ExecutionStatus Status { get; private set; }

    public string? MessageId { get; private set; }

    public string? Error { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset? CompletedAt { get; private set; }

    public static Execution Start(IncomingComment comment, Automation automation, DateTimeOffset now) => new()
    {
        Id = comment.CommentId,
        AutomationId = automation.Id,
        AutomationName = automation.Name,
        CommentId = comment.CommentId,
        CommentText = comment.Text,
        CommenterUsername = comment.CommenterUsername,
        Status = ExecutionStatus.Processing,
        CreatedAt = now,
    };

    public void MarkSent(string? messageId, DateTimeOffset now)
    {
        Status = ExecutionStatus.Sent;
        MessageId = messageId;
        Error = null;
        CompletedAt = now;
    }

    public void MarkFailed(string error, DateTimeOffset now)
    {
        Status = ExecutionStatus.Failed;
        Error = error;
        CompletedAt = now;
    }
}
