using Nesaro.Domain.Entities;
using Nesaro.Domain.Enums;
using Nesaro.Domain.Services;
using Xunit;

namespace Nesaro.Domain.Tests;

public class KeywordMatcherTests
{
    [Theory]
    [InlineData("QUERO", "quero", true)]
    [InlineData("Quero o link!!", "QUERO", true)]
    [InlineData("quéro 🔥", "QUERO", true)]
    [InlineData("eu quero muito", "QUERO", true)]
    [InlineData("querosene", "QUERO", false)]
    [InlineData("não", "QUERO", false)]
    [InlineData("manda o link aí", "o link", true)]
    public void Contains_casa_palavra_inteira(string comment, string keyword, bool expected) =>
        Assert.Equal(expected, KeywordMatcher.IsMatch(comment, keyword, MatchType.Contains));

    [Theory]
    [InlineData("QUERO!", "quero", true)]
    [InlineData("  link ", "LINK", true)]
    [InlineData("quero o link", "QUERO", false)]
    public void Exact_exige_so_a_palavra(string comment, string keyword, bool expected) =>
        Assert.Equal(expected, KeywordMatcher.IsMatch(comment, keyword, MatchType.Exact));

    [Fact]
    public void Palavra_chave_vazia_nunca_casa() =>
        Assert.False(KeywordMatcher.IsMatch("qualquer coisa", "  ", MatchType.Contains));

    [Fact]
    public void Automacao_pausada_nao_dispara()
    {
        var automation = NewAutomation(active: false);
        Assert.False(automation.Matches("post-1", "QUERO"));
    }

    [Fact]
    public void Automacao_de_um_post_so_vale_para_esse_post()
    {
        var automation = NewAutomation(mediaId: "post-1");
        Assert.True(automation.Matches("post-1", "QUERO"));
        Assert.False(automation.Matches("post-2", "QUERO"));
    }

    [Fact]
    public void Link_entra_no_lugar_do_marcador()
    {
        var automation = NewAutomation(message: "Aqui está: {link} 💌", link: "https://nesaro.com.br");
        Assert.Equal("Aqui está: https://nesaro.com.br 💌", automation.BuildDirectMessage());
    }

    [Fact]
    public void Link_vai_no_final_quando_nao_tem_marcador()
    {
        var automation = NewAutomation(message: "Obrigado!", link: "https://nesaro.com.br");
        Assert.Equal("Obrigado!\nhttps://nesaro.com.br", automation.BuildDirectMessage());
    }

    private static Automation NewAutomation(
        bool active = true,
        string? mediaId = null,
        string message = "Oi!",
        string? link = null) => new()
    {
        Id = "a1",
        OwnerUid = "u1",
        Name = "Teste",
        Keyword = "QUERO",
        Active = active,
        MediaId = mediaId,
        DirectMessage = message,
        Link = link,
    };
}
