using Npgsql;
using UniversityManagementAPI.Repositories.Interfaces;

namespace UniversityManagementAPI.Repositories;

public sealed class PostgresUnitRepository : IPostgresUnitRepository
{
    private readonly IPostgresRequestTransaction _transaction;

    public PostgresUnitRepository(IPostgresRequestTransaction transaction)
    {
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<UnitDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
                u.unit_id,
                u.unit_name,
                u.head_staff_id,
                s.full_name AS head_staff_name
            FROM university.units u
            LEFT JOIN university.staff s
              ON s.staff_id = u.head_staff_id
            ORDER BY u.unit_id
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);

        var units = new List<UnitDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var headStaffIdOrdinal = reader.GetOrdinal("head_staff_id");
            var headStaffNameOrdinal = reader.GetOrdinal("head_staff_name");

            units.Add(new UnitDto
            {
                UnitId = reader.GetString(reader.GetOrdinal("unit_id")),
                UnitName = reader.GetString(reader.GetOrdinal("unit_name")),
                HeadStaffId = reader.IsDBNull(headStaffIdOrdinal)
                    ? null
                    : reader.GetString(headStaffIdOrdinal),
                HeadStaffName = reader.IsDBNull(headStaffNameOrdinal)
                    ? null
                    : reader.GetString(headStaffNameOrdinal)
            });
        }

        return units;
    }

    public async Task CreateAsync(
        CreateUnitRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            INSERT INTO university.units (
                unit_id,
                unit_name,
                head_staff_id
            ) VALUES (
                $1,
                $2,
                $3
            )
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        command.Parameters.AddWithValue(request.UnitId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(request.UnitName.Trim());
        command.Parameters.AddWithValue(
            string.IsNullOrWhiteSpace(request.HeadStaffId)
                ? (object)DBNull.Value
                : request.HeadStaffId.Trim().ToUpperInvariant());

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string unitId,
        UpdateUnitRequest request,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            UPDATE university.units
            SET
                unit_name = $1,
                head_staff_id = $2
            WHERE unit_id = $3
            """;

        await using var command = new NpgsqlCommand(sql, _transaction.Connection, _transaction.Transaction);
        command.Parameters.AddWithValue(request.UnitName.Trim());
        command.Parameters.AddWithValue(
            string.IsNullOrWhiteSpace(request.HeadStaffId)
                ? (object)DBNull.Value
                : request.HeadStaffId.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(unitId.Trim().ToUpperInvariant());

        var updated = await command.ExecuteNonQueryAsync(cancellationToken);
        return updated == 1;
    }
}