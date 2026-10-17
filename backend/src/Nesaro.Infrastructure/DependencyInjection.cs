using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Nesaro.Application.Abstractions;
using Nesaro.Infrastructure.Firestore;
using Nesaro.Infrastructure.Instagram;
using Nesaro.Infrastructure.Options;
using Nesaro.Infrastructure.Queue;
using Nesaro.Infrastructure.Security;
using Nesaro.Infrastructure.Time;
using Nesaro.Infrastructure.Workers;

namespace Nesaro.Infrastructure;

/// <summary>
/// Registro da camada Infrastructure: liga cada interface da Application à sua implementação.
///
/// Tempos de vida:
///   Singleton → objetos caros ou sem estado por requisição (FirestoreDb, FirebaseApp, fila, relógio, state OAuth)
///   Scoped    → repositórios e token store (uma instância por requisição/item da fila)
///   HttpClient tipado → cliente da Meta (a fábrica cuida do ciclo de vida das conexões)
///   HostedService → workers em segundo plano
/// </summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Options Pattern com validação: se faltar configuração, a API nem sobe.
        services.AddOptions<MetaOptions>()
            .Bind(configuration.GetSection(MetaOptions.Section))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services.AddOptions<FirebaseProjectOptions>()
            .Bind(configuration.GetSection(FirebaseProjectOptions.Section))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        // Chaves de criptografia em disco (no Docker, um volume). Faça backup desta pasta.
        services.AddDataProtection()
            .SetApplicationName("Nesaro")
            .PersistKeysToFileSystem(new DirectoryInfo(configuration["DataProtection:KeysPath"] ?? "keys"));

        // Firebase / Firestore — credenciais da conta de serviço via GOOGLE_APPLICATION_CREDENTIALS.
        services.AddSingleton(sp =>
        {
            var firebase = sp.GetRequiredService<IOptions<FirebaseProjectOptions>>().Value;
            return FirestoreDb.Create(firebase.ProjectId);
        });

        services.AddSingleton(sp =>
        {
            var firebase = sp.GetRequiredService<IOptions<FirebaseProjectOptions>>().Value;
            return FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.GetApplicationDefault(),
                ProjectId = firebase.ProjectId,
            });
        });

        // Persistência
        services.AddScoped<IAutomationRepository, FirestoreAutomationRepository>();
        services.AddScoped<IExecutionRepository, FirestoreExecutionRepository>();
        services.AddScoped<IInstagramConnectionRepository, FirestoreInstagramConnectionRepository>();
        services.AddScoped<ITokenStore, FirestoreTokenStore>();

        // Integrações externas
        services.AddHttpClient<IInstagramClient, InstagramClient>(client =>
        {
            client.Timeout = TimeSpan.FromSeconds(20);
        });

        // Serviços de suporte
        services.AddSingleton<IClock, UtcClock>();
        services.AddSingleton<IOAuthStateService, OAuthStateService>();
        services.AddSingleton<IIdTokenVerifier, FirebaseIdTokenVerifier>();
        services.AddSingleton<ICommentQueue, ChannelCommentQueue>();

        // Processamento em segundo plano
        services.AddHostedService<CommentProcessingWorker>();
        services.AddHostedService<TokenRefreshWorker>();

        return services;
    }
}
