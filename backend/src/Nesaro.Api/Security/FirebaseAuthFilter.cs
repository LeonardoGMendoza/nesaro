using Nesaro.Application.Abstractions;

namespace Nesaro.Api.Security;

/// <summary>
/// Filtro dos endpoints chamados pelo app: exige "Authorization: Bearer {token do Firebase}".
/// O IIdTokenVerifier chega por injeção no construtor.
/// </summary>
public sealed class FirebaseAuthFilter(IIdTokenVerifier verifier) : IEndpointFilter
{
    private const string UidKey = "nesaro.uid";
    private const string BearerPrefix = "Bearer ";

    public static string GetUid(HttpContext context) =>
        context.Items[UidKey] as string ?? throw new InvalidOperationException("Endpoint sem FirebaseAuthFilter.");

    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var header = context.HttpContext.Request.Headers.Authorization.ToString();
        if (!header.StartsWith(BearerPrefix, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Unauthorized();
        }

        var uid = await verifier.VerifyAsync(header[BearerPrefix.Length..].Trim(), context.HttpContext.RequestAborted);
        if (uid is null)
        {
            return Results.Unauthorized();
        }

        context.HttpContext.Items[UidKey] = uid;
        return await next(context);
    }
}
