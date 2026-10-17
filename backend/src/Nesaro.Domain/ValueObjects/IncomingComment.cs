namespace Nesaro.Domain.ValueObjects;

/// <summary>Um comentário recebido pelo webhook do Instagram.</summary>
/// <param name="IgAccountId">ID da conta profissional que recebeu o comentário (dona da automação).</param>
/// <param name="CommentId">ID do comentário — usado para a resposta privada e para evitar duplicidade.</param>
/// <param name="MediaId">ID do post ou Reel comentado.</param>
/// <param name="Text">Texto do comentário.</param>
/// <param name="CommenterId">ID de quem comentou (escopo do Instagram).</param>
/// <param name="CommenterUsername">@ de quem comentou.</param>
public sealed record IncomingComment(
    string IgAccountId,
    string CommentId,
    string? MediaId,
    string Text,
    string? CommenterId,
    string? CommenterUsername)
{
    /// <summary>Comentários feitos pela própria conta (ex.: a resposta pública da Nesaro) nunca disparam automação.</summary>
    public bool IsFromAccountOwner => CommenterId is not null && CommenterId == IgAccountId;
}
