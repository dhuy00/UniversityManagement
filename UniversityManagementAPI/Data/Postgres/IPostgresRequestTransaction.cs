using Npgsql;

public interface IPostgresRequestTransaction : IAsyncDisposable
{
    NpgsqlConnection Connection { get; }
    NpgsqlTransaction Transaction { get; }
    long UserId { get; }

    Task InitializeAsync(CancellationToken cancellationToken = default);
    Task CommitAsync(CancellationToken cancellationToken = default);
}
