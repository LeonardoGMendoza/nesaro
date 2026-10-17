using Google.Cloud.Firestore;
using Nesaro.Application.Abstractions;
using Nesaro.Domain.Entities;
using Nesaro.Domain.Enums;

namespace Nesaro.Infrastructure.Firestore;

internal sealed class FirestoreAutomationRepository(FirestoreDb db) : IAutomationRepository
{
    public async Task<IReadOnlyList<Automation>> GetActiveAsync(string ownerUid, CancellationToken cancellationToken)
    {
        var snapshot = await FirestorePaths.Automations(db, ownerUid)
            .WhereEqualTo("active", true)
            .GetSnapshotAsync(cancellationToken);

        return snapshot.Documents
            .Select(doc => Map(ownerUid, doc))
            .ToList();
    }

    public Task IncrementStatAsync(string ownerUid, string automationId, AutomationStat stat, CancellationToken cancellationToken)
    {
        var field = stat switch
        {
            AutomationStat.Matched => "stats.matched",
            AutomationStat.Sent => "stats.sent",
            AutomationStat.Failed => "stats.failed",
            _ => throw new ArgumentOutOfRangeException(nameof(stat), stat, null),
        };

        // Increment é atômico: vários comentários ao mesmo tempo não perdem contagem.
        return FirestorePaths.Automations(db, ownerUid)
            .Document(automationId)
            .UpdateAsync(new Dictionary<string, object> { [field] = FieldValue.Increment(1) }, cancellationToken: cancellationToken);
    }

    private static Automation Map(string ownerUid, DocumentSnapshot doc)
    {
        IReadOnlyDictionary<string, object> data = doc.ToDictionary();

        return new Automation
        {
            Id = doc.Id,
            OwnerUid = ownerUid,
            Name = data.GetString("name") ?? string.Empty,
            Keyword = data.GetString("keyword") ?? string.Empty,
            MatchType = data.GetString("matchType") == "exact" ? MatchType.Exact : MatchType.Contains,
            MediaId = data.GetString("mediaId"),
            PublicReply = data.GetString("publicReply"),
            DirectMessage = data.GetString("dmMessage") ?? string.Empty,
            Link = data.GetString("link"),
            Active = data.GetBool("active"),
        };
    }
}
