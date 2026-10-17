namespace Nesaro.Domain.Enums;

/// <summary>Contadores que aparecem no painel de cada automação.</summary>
public enum AutomationStat
{
    /// <summary>Comentários que casaram com a regra.</summary>
    Matched = 0,

    /// <summary>Mensagens enviadas com sucesso pelo Direct.</summary>
    Sent = 1,

    /// <summary>Tentativas de envio que falharam.</summary>
    Failed = 2,
}
