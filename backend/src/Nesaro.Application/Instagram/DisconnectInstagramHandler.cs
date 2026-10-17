using Nesaro.Application.Abstractions;

namespace Nesaro.Application.Instagram;

/// <summary>Remove o token e a ligação da conta. Depois disso nenhuma automação dispara.</summary>
public sealed class DisconnectInstagramHandler(ITokenStore tokens, IInstagramConnectionRepository connections)
{
    public async Task HandleAsync(string ownerUid, CancellationToken cancellationToken)
    {
        var connection = await connections.GetAsync(ownerUid, cancellationToken);

        await tokens.DeleteAsync(ownerUid, cancellationToken);

        if (connection is not null)
        {
            await connections.RemoveAsync(connection, cancellationToken);
        }
    }
}
