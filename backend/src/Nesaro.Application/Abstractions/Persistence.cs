using Nesaro.Domain.Entities;
using Nesaro.Domain.Enums;

namespace Nesaro.Application.Abstractions;

/// <summary>Leitura das automações e atualização dos contadores.</summary>
public interface IAutomationRepository
{
    Task<IReadOnlyList<Automation>> GetActiveAsync(string ownerUid, CancellationToken cancellationToken);

    Task IncrementStatAsync(string ownerUid, string automationId, AutomationStat stat, CancellationToken cancellationToken);
}

/// <summary>Histórico de execuções.</summary>
public interface IExecutionRepository
{
    /// <summary>
    /// Cria a execução só se ela ainda não existir.
    /// Retorna false quando o comentário já foi processado (proteção contra duplicidade).
    /// </summary>
    Task<bool> TryCreateAsync(string ownerUid, Execution execution, CancellationToken cancellationToken);

    Task UpdateAsync(string ownerUid, Execution execution, CancellationToken cancellationToken);
}

/// <summary>Ligação entre o cliente da Nesaro e a conta do Instagram.</summary>
public interface IInstagramConnectionRepository
{
    /// <summary>Descobre de qual cliente é a conta que recebeu o comentário.</summary>
    Task<string?> FindOwnerUidAsync(string igAccountId, CancellationToken cancellationToken);

    Task<InstagramConnection?> GetAsync(string ownerUid, CancellationToken cancellationToken);

    Task SaveAsync(InstagramConnection connection, CancellationToken cancellationToken);

    Task RemoveAsync(InstagramConnection connection, CancellationToken cancellationToken);
}

/// <summary>Token de acesso do Instagram de um cliente.</summary>
public sealed record StoredToken(string OwnerUid, string IgAccountId, string AccessToken, DateTimeOffset ExpiresAt);

/// <summary>
/// Guarda os tokens fora do alcance do app. A implementação é responsável por criptografar.
/// </summary>
public interface ITokenStore
{
    Task SaveAsync(StoredToken token, CancellationToken cancellationToken);

    Task<StoredToken?> GetAsync(string ownerUid, CancellationToken cancellationToken);

    Task DeleteAsync(string ownerUid, CancellationToken cancellationToken);

    Task<IReadOnlyList<StoredToken>> ListExpiringAsync(DateTimeOffset before, CancellationToken cancellationToken);
}
