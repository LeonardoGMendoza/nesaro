using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Nesaro.Api.Contracts;
using Nesaro.Api.Security;
using Nesaro.Application.Abstractions;
using Nesaro.Domain.ValueObjects;
using Nesaro.Infrastructure.Options;

namespace Nesaro.Api.Endpoints;

public static class WebhookEndpoints
{
    private static readonly JsonSerializerOptions PayloadJson = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true,
        NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString,
    };

    public static IEndpointRouteBuilder MapWebhookEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/webhooks/instagram");

        // 1) Verificação: a Meta chama uma vez ao cadastrar o webhook.
        group.MapGet("", (
            [FromQuery(Name = "hub.mode")] string? mode,
            [FromQuery(Name = "hub.verify_token")] string? verifyToken,
            [FromQuery(Name = "hub.challenge")] string? challenge,
            IOptions<MetaOptions> options) =>
        {
            return mode == "subscribe" && verifyToken == options.Value.WebhookVerifyToken && challenge is not null
                ? Results.Text(challenge)
                : Results.StatusCode(StatusCodes.Status403Forbidden);
        });

        // 2) Eventos: valida a assinatura, coloca na fila e responde 200 rápido.
        group.MapPost("", async (
            HttpRequest request,
            MetaSignatureValidator signatureValidator,
            ICommentQueue queue,
            ILoggerFactory loggerFactory,
            CancellationToken cancellationToken) =>
        {
            using var buffer = new MemoryStream();
            await request.Body.CopyToAsync(buffer, cancellationToken);
            var body = buffer.ToArray();

            if (!signatureValidator.IsValid(body, request.Headers["X-Hub-Signature-256"]))
            {
                return Results.Unauthorized();
            }

            InstagramWebhookPayload? payload;
            try
            {
                payload = JsonSerializer.Deserialize<InstagramWebhookPayload>(body, PayloadJson);
            }
            catch (JsonException ex)
            {
                loggerFactory.CreateLogger("Webhook").LogWarning(ex, "Payload do webhook inválido.");
                return Results.BadRequest();
            }

            foreach (var comment in ExtractComments(payload))
            {
                await queue.EnqueueAsync(comment, cancellationToken);
            }

            return Results.Ok();
        });

        return app;
    }

    private static IEnumerable<IncomingComment> ExtractComments(InstagramWebhookPayload? payload)
    {
        if (payload?.Entry is null)
        {
            yield break;
        }

        foreach (var entry in payload.Entry)
        {
            if (entry.Id is null || entry.Changes is null)
            {
                continue;
            }

            foreach (var change in entry.Changes)
            {
                var value = change.Value;
                if (change.Field != "comments" || value?.Id is null || string.IsNullOrWhiteSpace(value.Text))
                {
                    continue;
                }

                yield return new IncomingComment(
                    IgAccountId: entry.Id,
                    CommentId: value.Id,
                    MediaId: value.Media?.Id,
                    Text: value.Text,
                    CommenterId: value.From?.Id,
                    CommenterUsername: value.From?.Username);
            }
        }
    }
}
