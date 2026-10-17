using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Options;
using Nesaro.Application.Abstractions;
using Nesaro.Infrastructure.Options;

namespace Nesaro.Infrastructure.Instagram;

/// <summary>
/// Cliente da API oficial: "Instagram API with Instagram Login".
/// Registrado como HttpClient tipado (AddHttpClient), então o HttpClient é gerenciado pela fábrica.
/// </summary>
internal sealed class InstagramClient(HttpClient http, IOptions<MetaOptions> options) : IInstagramClient
{
    private const string AuthorizeEndpoint = "https://www.instagram.com/oauth/authorize";
    private const string TokenEndpoint = "https://api.instagram.com/oauth/access_token";
    private const string GraphHost = "https://graph.instagram.com";

    private readonly MetaOptions _options = options.Value;

    public string BuildAuthorizeUrl(string state) =>
        QueryHelpers.AddQueryString(AuthorizeEndpoint, new Dictionary<string, string?>
        {
            ["client_id"] = _options.AppId,
            ["redirect_uri"] = _options.RedirectUri,
            ["response_type"] = "code",
            ["scope"] = _options.Scopes,
            ["state"] = state,
        });

    public async Task<ShortLivedToken> ExchangeCodeAsync(string code, CancellationToken cancellationToken)
    {
        using var content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["client_id"] = _options.AppId,
            ["client_secret"] = _options.AppSecret,
            ["grant_type"] = "authorization_code",
            ["redirect_uri"] = _options.RedirectUri,
            ["code"] = code,
        });

        using var response = await http.PostAsync(TokenEndpoint, content, cancellationToken);
        var json = await ReadAsync(response, cancellationToken);

        // A Meta já respondeu nos dois formatos: { data: [ {...} ] } e { ... }.
        var node = json.TryGetProperty("data", out var data) && data.ValueKind == JsonValueKind.Array && data.GetArrayLength() > 0
            ? data[0]
            : json;

        return new ShortLivedToken(
            node.GetProperty("access_token").GetString()!,
            ReadId(node.GetProperty("user_id")));
    }

    public async Task<LongLivedToken> ExchangeForLongLivedAsync(string shortLivedToken, CancellationToken cancellationToken)
    {
        var url = QueryHelpers.AddQueryString($"{GraphHost}/access_token", new Dictionary<string, string?>
        {
            ["grant_type"] = "ig_exchange_token",
            ["client_secret"] = _options.AppSecret,
            ["access_token"] = shortLivedToken,
        });

        using var response = await http.GetAsync(url, cancellationToken);
        return ReadLongLived(await ReadAsync(response, cancellationToken));
    }

    public async Task<LongLivedToken> RefreshAsync(string longLivedToken, CancellationToken cancellationToken)
    {
        var url = QueryHelpers.AddQueryString($"{GraphHost}/refresh_access_token", new Dictionary<string, string?>
        {
            ["grant_type"] = "ig_refresh_token",
            ["access_token"] = longLivedToken,
        });

        using var response = await http.GetAsync(url, cancellationToken);
        return ReadLongLived(await ReadAsync(response, cancellationToken));
    }

    public async Task<InstagramProfile> GetProfileAsync(string accessToken, CancellationToken cancellationToken)
    {
        using var request = Authorized(HttpMethod.Get, Graph("me?fields=user_id,username"), accessToken);
        using var response = await http.SendAsync(request, cancellationToken);
        var json = await ReadAsync(response, cancellationToken);

        // user_id = ID da conta profissional, o mesmo que chega no webhook (entry.id).
        return new InstagramProfile(
            ReadId(json.GetProperty("user_id")),
            json.TryGetProperty("username", out var username) ? username.GetString() ?? string.Empty : string.Empty);
    }

    public async Task SubscribeToCommentsAsync(string accessToken, CancellationToken cancellationToken)
    {
        using var request = Authorized(HttpMethod.Post, Graph("me/subscribed_apps?subscribed_fields=comments"), accessToken);
        using var response = await http.SendAsync(request, cancellationToken);
        await ReadAsync(response, cancellationToken);
    }

    public async Task<string?> SendPrivateReplyAsync(
        string accessToken,
        string igAccountId,
        string commentId,
        string text,
        CancellationToken cancellationToken)
    {
        using var request = Authorized(HttpMethod.Post, Graph($"{igAccountId}/messages"), accessToken);
        request.Content = JsonContent.Create(new
        {
            recipient = new { comment_id = commentId },
            message = new { text },
        });

        using var response = await http.SendAsync(request, cancellationToken);
        var json = await ReadAsync(response, cancellationToken);

        return json.TryGetProperty("message_id", out var messageId) ? messageId.GetString() : null;
    }

    public async Task ReplyToCommentAsync(string accessToken, string commentId, string text, CancellationToken cancellationToken)
    {
        using var request = Authorized(HttpMethod.Post, Graph($"{commentId}/replies"), accessToken);
        request.Content = new FormUrlEncodedContent(new Dictionary<string, string> { ["message"] = text });

        using var response = await http.SendAsync(request, cancellationToken);
        await ReadAsync(response, cancellationToken);
    }

    private string Graph(string pathAndQuery) => $"{GraphHost}/{_options.GraphVersion}/{pathAndQuery}";

    private static HttpRequestMessage Authorized(HttpMethod method, string url, string accessToken)
    {
        var request = new HttpRequestMessage(method, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        return request;
    }

    private static async Task<JsonElement> ReadAsync(HttpResponseMessage response, CancellationToken cancellationToken)
    {
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        JsonElement json;
        try
        {
            using var document = JsonDocument.Parse(string.IsNullOrWhiteSpace(body) ? "{}" : body);
            json = document.RootElement.Clone();
        }
        catch (JsonException)
        {
            throw new InstagramApiException($"Resposta inesperada da Meta (HTTP {(int)response.StatusCode}).", (int)response.StatusCode);
        }

        if (!response.IsSuccessStatusCode)
        {
            var message = json.TryGetProperty("error", out var error) && error.TryGetProperty("message", out var text)
                ? text.GetString()
                : json.TryGetProperty("error_message", out var legacy) ? legacy.GetString() : null;

            throw new InstagramApiException(message ?? $"Erro HTTP {(int)response.StatusCode} na API da Meta.", (int)response.StatusCode);
        }

        return json;
    }

    private static LongLivedToken ReadLongLived(JsonElement json) => new(
        json.GetProperty("access_token").GetString()!,
        json.TryGetProperty("expires_in", out var expires) ? expires.GetInt64() : 60L * 24 * 60 * 60);

    // IDs às vezes chegam como número e às vezes como texto.
    private static string ReadId(JsonElement value) =>
        value.ValueKind == JsonValueKind.String ? value.GetString()! : value.GetRawText();
}
