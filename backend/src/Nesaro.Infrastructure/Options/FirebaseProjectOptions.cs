using System.ComponentModel.DataAnnotations;

namespace Nesaro.Infrastructure.Options;

/// <summary>
/// Projeto Firebase (o mesmo do app). As credenciais vêm da conta de serviço apontada
/// pela variável GOOGLE_APPLICATION_CREDENTIALS.
/// </summary>
public sealed class FirebaseProjectOptions
{
    public const string Section = "Firebase";

    [Required]
    public string ProjectId { get; set; } = string.Empty;
}
