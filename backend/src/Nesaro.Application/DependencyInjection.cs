using Microsoft.Extensions.DependencyInjection;
using Nesaro.Application.Comments;
using Nesaro.Application.Instagram;

namespace Nesaro.Application;

/// <summary>Registro da camada Application. Cada camada registra só o que é dela.</summary>
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        // Casos de uso: Scoped — uma instância por requisição (ou por item da fila).
        services.AddScoped<ProcessCommentHandler>();
        services.AddScoped<ConnectInstagramHandler>();
        services.AddScoped<DisconnectInstagramHandler>();
        services.AddScoped<RefreshInstagramTokensHandler>();

        return services;
    }
}
