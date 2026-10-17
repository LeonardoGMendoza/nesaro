using System.Globalization;
using System.Text;
using Nesaro.Domain.Enums;

namespace Nesaro.Domain.Services;

/// <summary>
/// Regra de negócio pura: decide se um comentário ativa uma palavra-chave.
/// Ignora maiúsculas/minúsculas, acentos, pontuação e emojis.
/// </summary>
public static class KeywordMatcher
{
    public static bool IsMatch(string? commentText, string? keyword, MatchType matchType)
    {
        var text = Normalize(commentText);
        var key = Normalize(keyword);

        if (key.Length == 0 || text.Length == 0)
        {
            return false;
        }

        return matchType switch
        {
            MatchType.Exact => text == key,
            _ => $" {text} ".Contains($" {key} ", StringComparison.Ordinal),
        };
    }

    /// <summary>
    /// "  Quéro, o LINK!! 🔥 " → "QUERO O LINK"
    /// </summary>
    public static string Normalize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var decomposed = value.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(decomposed.Length);
        var lastWasSpace = true;

        foreach (var c in decomposed)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) == UnicodeCategory.NonSpacingMark)
            {
                continue;
            }

            if (char.IsLetterOrDigit(c))
            {
                builder.Append(char.ToUpperInvariant(c));
                lastWasSpace = false;
            }
            else if (!lastWasSpace)
            {
                builder.Append(' ');
                lastWasSpace = true;
            }
        }

        return builder.ToString().TrimEnd();
    }
}
