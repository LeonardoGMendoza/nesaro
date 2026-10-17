namespace Nesaro.Api.Contracts;

// Formato que a Meta envia ao webhook (campos em snake_case, lidos com JsonNamingPolicy.SnakeCaseLower).
//
// {
//   "object": "instagram",
//   "entry": [{
//     "id": "<ID da conta profissional>",
//     "time": 1700000000,
//     "changes": [{
//       "field": "comments",
//       "value": {
//         "id": "<ID do comentário>",
//         "text": "QUERO",
//         "parent_id": "<se for resposta>",
//         "from": { "id": "<ID de quem comentou>", "username": "fulano" },
//         "media": { "id": "<ID do post>", "media_product_type": "REELS" }
//       }
//     }]
//   }]
// }

public sealed record InstagramWebhookPayload(string? Object, List<WebhookEntry>? Entry);

public sealed record WebhookEntry(string? Id, long? Time, List<WebhookChange>? Changes);

public sealed record WebhookChange(string? Field, CommentValue? Value);

public sealed record CommentValue(string? Id, string? Text, string? ParentId, WebhookUser? From, WebhookMedia? Media);

public sealed record WebhookUser(string? Id, string? Username);

public sealed record WebhookMedia(string? Id, string? MediaProductType);
