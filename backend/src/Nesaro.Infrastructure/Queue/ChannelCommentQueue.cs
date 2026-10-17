using System.Threading.Channels;
using Nesaro.Application.Abstractions;
using Nesaro.Domain.ValueObjects;

namespace Nesaro.Infrastructure.Queue;

/// <summary>
/// Fila em memória (System.Threading.Channels). Suficiente para o MVP num servidor só.
/// Para crescer, troque por Redis ou RabbitMQ implementando a mesma ICommentQueue —
/// nenhuma outra camada muda.
/// </summary>
internal sealed class ChannelCommentQueue : ICommentQueue
{
    private readonly Channel<IncomingComment> _channel = Channel.CreateBounded<IncomingComment>(
        new BoundedChannelOptions(capacity: 5_000)
        {
            FullMode = BoundedChannelFullMode.Wait,
            SingleReader = false,
            SingleWriter = false,
        });

    public ValueTask EnqueueAsync(IncomingComment comment, CancellationToken cancellationToken) =>
        _channel.Writer.WriteAsync(comment, cancellationToken);

    public IAsyncEnumerable<IncomingComment> ReadAllAsync(CancellationToken cancellationToken) =>
        _channel.Reader.ReadAllAsync(cancellationToken);
}
