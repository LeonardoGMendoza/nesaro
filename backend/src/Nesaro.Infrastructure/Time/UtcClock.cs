using Nesaro.Application.Abstractions;

namespace Nesaro.Infrastructure.Time;

internal sealed class UtcClock : IClock
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}
