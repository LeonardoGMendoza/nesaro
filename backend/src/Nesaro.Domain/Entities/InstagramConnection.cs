namespace Nesaro.Domain.Entities;

/// <summary>Conta profissional do Instagram ligada a um cliente da Nesaro.</summary>
/// <param name="OwnerUid">UID do cliente no Firebase Auth.</param>
/// <param name="IgAccountId">ID da conta profissional (o mesmo que chega no webhook).</param>
/// <param name="Username">@ da conta.</param>
/// <param name="ConnectedAt">Quando foi conectada.</param>
public sealed record InstagramConnection(
    string OwnerUid,
    string IgAccountId,
    string Username,
    DateTimeOffset ConnectedAt);
