using System.Net;
using Microsoft.Extensions.Options;
using Nesaro.Api.Security;
using Nesaro.Application.Abstractions;
using Nesaro.Application.Instagram;
using Nesaro.Infrastructure.Options;

namespace Nesaro.Api.Endpoints;

public static class InstagramAuthEndpoints
{
    public static IEndpointRouteBuilder MapInstagramAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/auth/instagram");

        // App → API: devolve a URL da Meta para abrir no navegador.
        group.MapPost("/start", (HttpContext http, ConnectInstagramHandler handler) =>
                Results.Ok(new { url = handler.Start(FirebaseAuthFilter.GetUid(http)) }))
            .AddEndpointFilter<FirebaseAuthFilter>();

        // Meta → API: o cliente autorizou (ou recusou). Mostra uma página simples.
        group.MapGet("/callback", async (
            string? code,
            string? state,
            string? error,
            ConnectInstagramHandler handler,
            IOptions<MetaOptions> options,
            ILoggerFactory loggerFactory,
            CancellationToken cancellationToken) =>
        {
            var returnUrl = options.Value.AppReturnUrl;

            if (!string.IsNullOrEmpty(error) || string.IsNullOrEmpty(code) || string.IsNullOrEmpty(state))
            {
                return CallbackPage(false, "A conexão foi cancelada. Volte ao app e tente de novo.", returnUrl);
            }

            try
            {
                var connection = await handler.CompleteAsync(code, state, cancellationToken);
                return CallbackPage(true, $"Instagram @{connection.Username} conectado à Nesaro!", returnUrl);
            }
            catch (InvalidOAuthStateException ex)
            {
                return CallbackPage(false, ex.Message, returnUrl);
            }
            catch (InstagramApiException ex)
            {
                loggerFactory.CreateLogger("InstagramAuth").LogWarning(ex, "Falha ao concluir a conexão do Instagram.");
                return CallbackPage(false, "O Instagram recusou a conexão. Confira se a conta é profissional e tente de novo.", returnUrl);
            }
        });

        // App → API: desconecta e apaga o token.
        group.MapPost("/disconnect", async (HttpContext http, DisconnectInstagramHandler handler, CancellationToken cancellationToken) =>
            {
                await handler.HandleAsync(FirebaseAuthFilter.GetUid(http), cancellationToken);
                return Results.NoContent();
            })
            .AddEndpointFilter<FirebaseAuthFilter>();

        return app;
    }

    private static IResult CallbackPage(bool success, string message, string? returnUrl)
    {
        var title = success ? "Tudo certo!" : "Não deu certo";
        var color = success ? "#1A7F4E" : "#B83A2A";
        var button = string.IsNullOrWhiteSpace(returnUrl)
            ? "<p>Pode fechar esta página e voltar ao app.</p>"
            : $"<p><a href=\"{WebUtility.HtmlEncode(returnUrl)}\">Voltar para o app</a></p>";

        var html = $$"""
            <!doctype html>
            <html lang="pt-BR">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>Nesaro</title>
              <style>
                body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #F5EFE3; color: #1F1B16; font-family: system-ui, sans-serif; }
                main { max-width: 420px; padding: 32px; text-align: center; }
                h1 { color: {{color}}; }
                a { display: inline-block; padding: 14px 24px; border-radius: 12px; background: #1F1B16; color: #F5EFE3; text-decoration: none; }
              </style>
            </head>
            <body>
              <main>
                <p><strong>NESARO</strong> · ネサロ</p>
                <h1>{{title}}</h1>
                <p>{{WebUtility.HtmlEncode(message)}}</p>
                {{button}}
              </main>
            </body>
            </html>
            """;

        return Results.Content(html, "text/html; charset=utf-8");
    }
}
