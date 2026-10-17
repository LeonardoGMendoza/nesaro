using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Nesaro.Application.Abstractions;

namespace Nesaro.Infrastructure.Security;

/// <summary>Confere o token de login que o app Flutter manda no cabeçalho Authorization.</summary>
internal sealed class FirebaseIdTokenVerifier(FirebaseApp firebaseApp) : IIdTokenVerifier
{
    public async Task<string?> VerifyAsync(string idToken, CancellationToken cancellationToken)
    {
        try
        {
            var token = await FirebaseAuth.GetAuth(firebaseApp).VerifyIdTokenAsync(idToken, cancellationToken);
            return token.Uid;
        }
        catch (FirebaseAuthException)
        {
            return null;
        }
        catch (ArgumentException)
        {
            return null;
        }
    }
}
