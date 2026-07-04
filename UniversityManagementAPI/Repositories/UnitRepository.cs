using System.Data;
using Oracle.ManagedDataAccess.Client;

public sealed class UnitRepository : IUnitRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public UnitRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<UnitDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var units = new List<UnitDto>();

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText = """
            SELECT
                u.UNIT_ID,
                u.UNIT_NAME,
                u.HEAD_STAFF_ID,
                s.FULL_NAME AS HEAD_STAFF_NAME
            FROM UNIVERSITY_APP.UNITS u
            LEFT JOIN UNIVERSITY_APP.STAFF s
              ON s.STAFF_ID = u.HEAD_STAFF_ID
            ORDER BY u.UNIT_ID
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var headStaffNameOrdinal = reader.GetOrdinal("HEAD_STAFF_NAME");

            units.Add(new UnitDto
            {
                UnitId = reader.GetString(reader.GetOrdinal("UNIT_ID")),
                UnitName = reader.GetString(reader.GetOrdinal("UNIT_NAME")),
                HeadStaffId = reader.GetString(reader.GetOrdinal("HEAD_STAFF_ID")),
                HeadStaffName = reader.IsDBNull(headStaffNameOrdinal)
                    ? null
                    : reader.GetString(headStaffNameOrdinal)
            });
        }

        return units;
    }

    public async Task<bool> UpdateAsync(
        string unitId,
        UpdateUnitRequest request,
        CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = connection.BeginTransaction();

        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.BindByName = true;
        command.CommandType = CommandType.Text;
        command.CommandText = """
            UPDATE UNIVERSITY_APP.UNITS
            SET UNIT_NAME = :unit_name
            WHERE UNIT_ID = :unit_id
            """;
        command.Parameters.Add("unit_name", OracleDbType.Varchar2).Value =
            request.UnitName.Trim();
        command.Parameters.Add("unit_id", OracleDbType.Varchar2).Value =
            unitId.Trim().ToUpperInvariant();

        var updated = await command.ExecuteNonQueryAsync(cancellationToken) == 1;
        if (updated)
        {
            await transaction.CommitAsync(cancellationToken);
        }
        else
        {
            await transaction.RollbackAsync(cancellationToken);
        }

        return updated;
    }
}
