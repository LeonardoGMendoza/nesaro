using Google.Cloud.Firestore;
using Nesaro.Application.Abstractions;
using Nesaro.Domain.Entities;

namespace Nesaro.Infrastructure.Firestore;

internal sealed class FirestoreInstagramConnectionRepository(FirestoreDb db) : IInstagramConnectionRepository
{
    public async Task<string?> FindOwnerUidAsync(string igAccountId, CancellationToken cancellationToken)
    {
        var snapshot = await FirestorePaths.IgAccount(db, igAccountId).GetSnapshotAsync(cancellationToken);
        return snapshot.Exists && snapshot.TryGetValue<string>("uid", out var uid) ? uid : null;
    }

    public async Task<InstagramConnection?> GetAsync(string ownerUid, CancellationToken cancellationToken)
    {
        var snapshot = await FirestorePaths.User(db, ownerUid).GetSnapshotAsync(cancellationToken);
        if (!snapshot.Exists || !snapshot.TryGetValue<Dictionary<string, object>>("instagram", out var instagram))
        {
            return null;
        }

        IReadOnlyDictionary<string, object> data = instagram;
        var igAccountId = data.GetString("igAccountId");
        if (!data.GetBool("connected") || igAccountId is null)
        {
            return null;
        }

        var connectedAt = data.TryGetValue("connectedAt", out var value) && value is Timestamp ts
            ? ts.ToDateTimeOffset()
            : DateTimeOffset.MinValue;

        return new InstagramConnection(ownerUid, igAccountId, data.GetString("username") ?? string.Empty, connectedAt);
    }

    public async Task SaveAsync(InstagramConnection connection, CancellationToken cancellationToken)
    {
        var batch = db.StartBatch();

        batch.Set(FirestorePaths.IgAccount(db, connection.IgAccountId), new Dictionary<string, object>
        {
            ["uid"] = connection.OwnerUid,
            ["username"] = connection.Username,
            ["updatedAt"] = Timestamp.FromDateTimeOffset(connection.ConnectedAt),
        });

        batch.Set(
            FirestorePaths.User(db, connection.OwnerUid),
            new Dictionary<string, object>
            {
                ["instagram"] = new Dictionary<string, object>
                {
                    ["connected"] = true,
                    ["igAccountId"] = connection.IgAccountId,
                    ["username"] = connection.Username,
                    ["connectedAt"] = Timestamp.FromDateTimeOffset(connection.ConnectedAt),
                },
            },
            SetOptions.MergeAll);

        await batch.CommitAsync(cancellationToken);
    }

    public async Task RemoveAsync(InstagramConnection connection, CancellationToken cancellationToken)
    {
        var batch = db.StartBatch();

        batch.Delete(FirestorePaths.IgAccount(db, connection.IgAccountId));
        batch.Update(
            FirestorePaths.User(db, connection.OwnerUid),
            new Dictionary<string, object>
            {
                ["instagram"] = new Dictionary<string, object> { ["connected"] = false },
            });

        await batch.CommitAsync(cancellationToken);
    }
}
