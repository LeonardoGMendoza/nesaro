using Nesaro.Domain.ValueObjects;

namespace Nesaro.Application.Abstractions;

/// <summary>Relógio injetável (facilita testes).</summary>
public interface IClock
{
    DateTimeOffset UtcNow { get; }
}

/// <summary>
/// Fila entre o webhook e o processamento. O webhook só enfileira e responde rápido à Meta;
/// o envio da DM acontece em segundo plano.
/// </summary>
public interface ICommentQueue
{
    ValueTask EnqueueAsync(IncomingComment comment, CancellationToken cancellationToken);

    IAsyncEnumerable<IncomingComment> ReadAllAsync(CancellationToken cancellationToken);
}

/// <summary>Gera e valida o "state" do OAuth, que carrega o UID do cliente com prazo de validade.</summary>
public interface IOAuthStateService
{
    string Create(string ownerUid);

    /// <summary>Retorna o UID, ou null se o state for inválido ou tiver expirado.</summary>
    string? ReadOwnerUid(string state);
}

/// <summary>Valida o token de login do app (Firebase Auth) e devolve o UID.</summary>
public interface IIdTokenVerifier
{
    Task<string?> VerifyAsync(string idToken, CancellationToken cancellationToken);
}
