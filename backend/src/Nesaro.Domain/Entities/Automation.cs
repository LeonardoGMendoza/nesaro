using MatchType = Nesaro.Domain.Enums.MatchType;
using Nesaro.Domain.Services;

namespace Nesaro.Domain.Entities;

/// <summary>Regra criada pelo cliente: "quando comentarem X, mande Y no Direct".</summary>
public sealed class Automation
{
    public const string LinkPlaceholder = "{link}";

    public required string Id { get; init; }

    public required string OwnerUid { get; init; }

    public required string Name { get; init; }

    public required string Keyword { get; init; }

    public MatchType MatchType { get; init; } = MatchType.Contains;

    /// <summary>Post ou Reel específico. Vazio = vale para todas as publicações.</summary>
    public string? MediaId { get; init; }

    /// <summary>Resposta pública opcional no próprio comentário.</summary>
    public string? PublicReply { get; init; }

    public required string DirectMessage { get; init; }

    public string? Link { get; init; }

    public bool Active { get; init; }

    public bool AppliesTo(string? mediaId) =>
        string.IsNullOrWhiteSpace(MediaId) || string.Equals(MediaId, mediaId, StringComparison.Ordinal);

    public bool Matches(string? mediaId, string commentText) =>
        Active && AppliesTo(mediaId) && KeywordMatcher.IsMatch(commentText, Keyword, MatchType);

    /// <summary>
    /// Monta o texto final do Direct. Se a mensagem tiver {link}, o link entra ali;
    /// senão, vai numa linha no final.
    /// </summary>
    public string BuildDirectMessage()
    {
        if (string.IsNullOrWhiteSpace(Link))
        {
            return DirectMessage.Replace(LinkPlaceholder, string.Empty, StringComparison.Ordinal).Trim();
        }

        return DirectMessage.Contains(LinkPlaceholder, StringComparison.Ordinal)
            ? DirectMessage.Replace(LinkPlaceholder, Link, StringComparison.Ordinal)
            : $"{DirectMessage.TrimEnd()}\n{Link}";
    }
}
