using Npgsql;

public sealed class PostgresRequestTransaction : IPostgresRequestTransaction
{
    private readonly NpgsqlDataSource _dataSource;
    private readonly IAuthenticatedPostgresUser _authenticatedUser;
    private NpgsqlConnection? _connection;
    private NpgsqlTransaction? _transaction;
    private bool _completed;
    private bool _disposed;

    public PostgresRequestTransaction(
        NpgsqlDataSource dataSource,
        IAuthenticatedPostgresUser authenticatedUser)
    {
        _dataSource = dataSource;
        _authenticatedUser = authenticatedUser;
    }

    public NpgsqlConnection Connection => _connection ?? throw new InvalidOperationException(
        "The PostgreSQL request transaction has not been initialized.");

    public NpgsqlTransaction Transaction => _transaction ?? throw new InvalidOperationException(
        "The PostgreSQL request transaction has not been initialized.");

    public long UserId { get; private set; }

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        if (_connection is not null)
        {
            throw new InvalidOperationException(
                "The PostgreSQL request transaction is already initialized.");
        }

        UserId = _authenticatedUser.GetRequiredUserId();
        _connection = await _dataSource.OpenConnectionAsync(cancellationToken);

        try
        {
            _transaction = await _connection.BeginTransactionAsync(cancellationToken);
            await using var command = new NpgsqlCommand(
                "SELECT university.set_security_context($1)",
                _connection,
                _transaction);
            command.Parameters.AddWithValue(UserId);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        catch
        {
            await DisposeResourcesAsync();
            throw;
        }
    }

    public async Task CommitAsync(CancellationToken cancellationToken = default)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        if (_transaction is null)
        {
            throw new InvalidOperationException(
                "The PostgreSQL request transaction has not been initialized.");
        }

        if (_completed)
        {
            throw new InvalidOperationException(
                "The PostgreSQL request transaction is already complete.");
        }

        await _transaction.CommitAsync(cancellationToken);
        _completed = true;
    }

    public async ValueTask DisposeAsync()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        await DisposeResourcesAsync();
        GC.SuppressFinalize(this);
    }

    private async ValueTask DisposeResourcesAsync()
    {
        if (_transaction is not null)
        {
            await _transaction.DisposeAsync();
            _transaction = null;
        }

        if (_connection is not null)
        {
            await _connection.DisposeAsync();
            _connection = null;
        }
    }
}
