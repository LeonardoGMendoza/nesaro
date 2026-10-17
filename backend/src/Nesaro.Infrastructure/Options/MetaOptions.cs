using System.ComponentModel.DataAnnotations;

namespace Nesaro.Infrastructure.Options;

/// <summary>Configuração do app no Meta for Developers. Vem de variáveis de ambiente (Meta__AppId etc.).</summary>
public sealed class MetaOptions
{
    public const string Section = "Meta";

    [Required]
    public string AppId { get; set; } = string.Empty;

    [Required]
    public string AppSecret { get; set; } = string.Empty;

    /// <summary>Ex.: https://api.nesaro.com.br/auth/instagram/callback — precisa estar cadastrado na Meta.</summary>
    [Required]
    [Url]
    public string RedirectUri { get; set; } = string.Empty;

    /// <summary>Senha que você inventa e cadastra no painel de Webhooks da Meta.</summary>
    [Required]
    public string WebhookVerifyToken { get; set; } = string.Empty;

    [Required]
    public string GraphVersion { get; set; } = "v23.0";

    [Required]
    public string Scopes { get; set; } =
        "instagram_business_basic,instagram_business_manage_comments,instagram_business_manage_messages";

    /// <summary>Opcional: link para voltar ao app depois de conectar (ex.: nesaro://instagram-conectado).</summary>
    public string? AppReturnUrl { get; set; }
}
