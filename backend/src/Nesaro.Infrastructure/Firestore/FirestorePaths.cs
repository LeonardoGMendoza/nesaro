using Google.Cloud.Firestore;

namespace Nesaro.Infrastructure.Firestore;

/// <summary>
/// Estrutura do banco, igual à usada pelo app Flutter:
///   users/{uid}                      perfil + campo "instagram" (só o backend grava)
///   users/{uid}/automations/{id}     regras criadas no app
///   users/{uid}/executions/{id}      histórico (só o backend grava; id = id do comentário)
///   igAccounts/{igAccountId}         índice conta do Instagram → uid (só backend)
///   igTokens/{uid}                   token criptografado (só backend)
/// </summary>
internal static class FirestorePaths
{
    public static DocumentReference User(FirestoreDb db, string uid) => db.Collection("users").Document(uid);

    public static CollectionReference Automations(FirestoreDb db, string uid) => User(db, uid).Collection("automations");

    public static CollectionReference Executions(FirestoreDb db, string uid) => User(db, uid).Collection("executions");

    public static DocumentReference IgAccount(FirestoreDb db, string igAccountId) => db.Collection("igAccounts").Document(igAccountId);

    public static CollectionReference IgTokens(FirestoreDb db) => db.Collection("igTokens");

    public static string? GetString(this IReadOnlyDictionary<string, object> data, string key) =>
        data.TryGetValue(key, out var value) && value is string text ? text : null;

    public static bool GetBool(this IReadOnlyDictionary<string, object> data, string key) =>
        data.TryGetValue(key, out var value) && value is bool flag && flag;
}
