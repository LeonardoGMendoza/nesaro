namespace Nesaro.Domain.Enums;

/// <summary>Como a palavra-chave é comparada com o comentário.</summary>
public enum MatchType
{
    /// <summary>O comentário contém a palavra-chave como palavra inteira ("quero o link" casa com QUERO).</summary>
    Contains = 0,

    /// <summary>O comentário é exatamente a palavra-chave ("QUERO!" casa, "quero o link" não).</summary>
    Exact = 1,
}
