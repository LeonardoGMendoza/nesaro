namespace Nesaro.Application.Abstractions;

public sealed record ShortLivedToken(string AccessToken, string UserId);

public sealed record LongLivedToken(string AccessToken, long ExpiresInSeconds);

public sealed record InstagramProfile(string UserId, string Username);

/// <summary>Erro devolvido pela API da Meta (permissão, prazo de 7 dias, token expirado...).</summary>
public sealed class InstagramApiException(string message, int statusCode) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}

/// <summary>Tudo o que a Nesaro faz na API oficial do Instagram (Instagram API com login do Instagram).</summary>
public interface IInstagramClient
{
    /// <summary>URL da tela da Meta onde o cliente autoriza a Nesaro.</summary>
    string BuildAuthorizeUrl(string state);

    Task<ShortLivedToken> ExchangeCodeAsync(string code, CancellationToken cancellationToken);

    Task<LongLivedToken> ExchangeForLongLivedAsync(string shortLivedToken, CancellationToken cancellationToken);

    Task<LongLivedToken> RefreshAsync(string longLivedToken, CancellationToken cancellationToken);

    Task<InstagramProfile> GetProfileAsync(string accessToken, CancellationToken cancellationToken);

    /// <summary>Pede à Meta para mandar os comentários dessa conta para o webhook.</summary>
    Task SubscribeToCommentsAsync(string accessToken, CancellationToken cancellationToken);

    /// <summary>Resposta privada (Direct) a um comentário. Retorna o ID da mensagem.</summary>
    Task<string?> SendPrivateReplyAsync(
        string accessToken,
        string igAccountId,
        string commentId,
        string text,
        CancellationToken cancellationToken);

    /// <summary>Resposta pública no próprio comentário.</summary>
    Task ReplyToCommentAsync(string accessToken, string commentId, string text, CancellationToken cancellationToken);
}
