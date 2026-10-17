using Google.Cloud.Firestore;
using Grpc.Core;
using Nesaro.Application.Abstractions;
using Nesaro.Domain.Entities;
using Nesaro.Domain.Enums;

namespace Nesaro.Infrastructure.Firestore;

internal sealed class FirestoreExecutionRepository(FirestoreDb db) : IExecutionRepository
{
    public async Task<bool> TryCreateAsync(string ownerUid, Execution execution, CancellationToken cancellationToken)
    {
        try
        {
            // CreateAsync falha se o documento já existir: é a trava de idempotência.
            await FirestorePaths.Executions(db, ownerUid)
                .Document(execution.Id)
                .CreateAsync(ToMap(execution), cancellationToken);
            return true;
        }
        catch (RpcException ex) when (ex.StatusCode == StatusCode.AlreadyExists)
        {
            return false;
        }
    }

    public Task UpdateAsync(string ownerUid, Execution execution, CancellationToken cancellationToken) =>
        FirestorePaths.Executions(db, ownerUid)
            .Document(execution.Id)
            .SetAsync(ToMap(execution), SetOptions.MergeAll, cancellationToken);

    private static Dictionary<string, object?> ToMap(Execution execution) => new()
    {
        ["automationId"] = execution.AutomationId,
        ["automationName"] = execution.AutomationName,
        ["commentId"] = execution.CommentId,
        ["commentText"] = execution.CommentText,
        ["commenterUsername"] = execution.CommenterUsername,
        ["status"] = execution.Status switch
        {
            ExecutionStatus.Sent => "sent",
            ExecutionStatus.Failed => "failed",
            _ => "processing",
        },
        ["messageId"] = execution.MessageId,
        ["error"] = execution.Error,
        ["createdAt"] = Timestamp.FromDateTimeOffset(execution.CreatedAt),
        ["completedAt"] = execution.CompletedAt is { } completed ? Timestamp.FromDateTimeOffset(completed) : null,
    };
}
