using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class StaffRepository : IStaffRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public StaffRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<StaffDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var staff = new List<StaffDto>();
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText = """
            SELECT
                STAFF_ID,
                FULL_NAME,
                GENDER,
                DATE_OF_BIRTH,
                ALLOWANCE,
                PHONE,
                ROLE_CODE,
                UNIT_ID,
                ORACLE_USERNAME,
                CAMPUS_ID
            FROM UNIVERSITY_APP.STAFF
            ORDER BY STAFF_ID
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var phoneOrdinal = reader.GetOrdinal("PHONE");
            staff.Add(new StaffDto
            {
                StaffId = reader.GetString(reader.GetOrdinal("STAFF_ID")),
                FullName = reader.GetString(reader.GetOrdinal("FULL_NAME")),
                Gender = reader.GetString(reader.GetOrdinal("GENDER")),
                DateOfBirth = reader.GetDateTime(reader.GetOrdinal("DATE_OF_BIRTH")),
                Allowance = reader.GetDecimal(reader.GetOrdinal("ALLOWANCE")),
                Phone = reader.IsDBNull(phoneOrdinal)
                    ? null
                    : reader.GetString(phoneOrdinal),
                RoleCode = reader.GetString(reader.GetOrdinal("ROLE_CODE")),
                UnitId = reader.GetString(reader.GetOrdinal("UNIT_ID")),
                OracleUsername = reader.GetString(
                    reader.GetOrdinal("ORACLE_USERNAME")),
                CampusId = reader.GetString(reader.GetOrdinal("CAMPUS_ID"))
            });
        }

        return staff;
    }

    public async Task CreateAsync(
        CreateStaffRequest request,
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
            INSERT INTO UNIVERSITY_APP.STAFF (
                STAFF_ID,
                FULL_NAME,
                GENDER,
                DATE_OF_BIRTH,
                ALLOWANCE,
                PHONE,
                ROLE_CODE,
                UNIT_ID,
                ORACLE_USERNAME,
                CAMPUS_ID
            ) VALUES (
                :staff_id,
                :full_name,
                :gender,
                :date_of_birth,
                :allowance,
                :phone,
                :role_code,
                :unit_id,
                :oracle_username,
                :campus_id
            )
            """;
        AddCommonParameters(command, request.FullName, request.Gender,
            request.DateOfBirth, request.Allowance, request.Phone,
            request.RoleCode, request.UnitId, request.CampusId);
        command.Parameters.Add("staff_id", OracleDbType.Varchar2).Value =
            request.StaffId.Trim().ToUpperInvariant();
        command.Parameters.Add("oracle_username", OracleDbType.Varchar2).Value =
            request.OracleUsername.Trim().ToUpperInvariant();

        await command.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        string staffId,
        UpdateStaffRequest request,
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
            UPDATE UNIVERSITY_APP.STAFF
            SET
                FULL_NAME = :full_name,
                GENDER = :gender,
                DATE_OF_BIRTH = :date_of_birth,
                ALLOWANCE = :allowance,
                PHONE = :phone,
                ROLE_CODE = :role_code,
                UNIT_ID = :unit_id,
                CAMPUS_ID = :campus_id
            WHERE STAFF_ID = :staff_id
            """;
        AddCommonParameters(command, request.FullName, request.Gender,
            request.DateOfBirth, request.Allowance, request.Phone,
            request.RoleCode, request.UnitId, request.CampusId);
        command.Parameters.Add("staff_id", OracleDbType.Varchar2).Value =
            staffId.Trim().ToUpperInvariant();

        var updated = await command.ExecuteNonQueryAsync(cancellationToken) == 1;
        await CompleteAsync(transaction, updated, cancellationToken);
        return updated;
    }

    public async Task<bool> DeleteAsync(
        string staffId,
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
            DELETE FROM UNIVERSITY_APP.STAFF
            WHERE STAFF_ID = :staff_id
            """;
        command.Parameters.Add("staff_id", OracleDbType.Varchar2).Value =
            staffId.Trim().ToUpperInvariant();

        var deleted = await command.ExecuteNonQueryAsync(cancellationToken) == 1;
        await CompleteAsync(transaction, deleted, cancellationToken);
        return deleted;
    }

    private static void AddCommonParameters(
        OracleCommand command,
        string fullName,
        string gender,
        DateTime dateOfBirth,
        decimal allowance,
        string? phone,
        string roleCode,
        string unitId,
        string campusId)
    {
        command.Parameters.Add("full_name", OracleDbType.Varchar2).Value =
            fullName.Trim();
        command.Parameters.Add("gender", OracleDbType.Varchar2).Value =
            gender.Trim().ToUpperInvariant();
        command.Parameters.Add("date_of_birth", OracleDbType.Date).Value =
            dateOfBirth;
        command.Parameters.Add("allowance", OracleDbType.Decimal).Value =
            allowance;
        command.Parameters.Add("phone", OracleDbType.Varchar2).Value =
            string.IsNullOrWhiteSpace(phone) ? DBNull.Value : phone.Trim();
        command.Parameters.Add("role_code", OracleDbType.Varchar2).Value =
            roleCode.Trim().ToUpperInvariant();
        command.Parameters.Add("unit_id", OracleDbType.Varchar2).Value =
            unitId.Trim().ToUpperInvariant();
        command.Parameters.Add("campus_id", OracleDbType.Varchar2).Value =
            campusId.Trim().ToUpperInvariant();
    }

    private static async Task CompleteAsync(
        OracleTransaction transaction,
        bool changed,
        CancellationToken cancellationToken)
    {
        if (changed)
        {
            await transaction.CommitAsync(cancellationToken);
        }
        else
        {
            await transaction.RollbackAsync(cancellationToken);
        }
    }
}
