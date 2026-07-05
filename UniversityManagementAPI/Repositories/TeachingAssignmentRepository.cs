using Oracle.ManagedDataAccess.Client;
using System.Data;

public sealed class TeachingAssignmentRepository
    : ITeachingAssignmentRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public TeachingAssignmentRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var assignments = new List<TeachingAssignmentDto>();

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText = """
            SELECT
                ta.LECTURER_ID,
                ta.COURSE_ID,
                c.COURSE_NAME,
                c.UNIT_ID,
                ta.SEMESTER,
                ta.ACADEMIC_YEAR,
                ta.PROGRAM_ID
            FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS ta
            JOIN UNIVERSITY_APP.COURSES c
              ON c.COURSE_ID = ta.COURSE_ID
            ORDER BY
                ta.ACADEMIC_YEAR DESC,
                ta.SEMESTER,
                ta.LECTURER_ID,
                ta.COURSE_ID,
                ta.PROGRAM_ID
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            assignments.Add(new TeachingAssignmentDto
            {
                LecturerId = reader.GetString(reader.GetOrdinal("LECTURER_ID")),
                CourseId = reader.GetString(reader.GetOrdinal("COURSE_ID")),
                CourseName = reader.GetString(reader.GetOrdinal("COURSE_NAME")),
                UnitId = reader.GetString(reader.GetOrdinal("UNIT_ID")),
                Semester = ReadInt32(reader, "SEMESTER"),
                AcademicYear = ReadInt32(reader, "ACADEMIC_YEAR"),
                ProgramId = reader.GetString(reader.GetOrdinal("PROGRAM_ID"))
            });
        }

        return assignments;
    }

    public async Task CreateAsync(
        SaveTeachingAssignmentRequest request,
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
            INSERT INTO UNIVERSITY_APP.TEACHING_ASSIGNMENTS (
                LECTURER_ID,
                COURSE_ID,
                SEMESTER,
                ACADEMIC_YEAR,
                PROGRAM_ID
            ) VALUES (
                :lecturer_id,
                :course_id,
                :semester,
                :academic_year,
                :program_id
            )
            """;
        AddAssignmentParameters(command, request);

        await command.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(
        TeachingAssignmentDto original,
        SaveTeachingAssignmentRequest request,
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
            UPDATE UNIVERSITY_APP.TEACHING_ASSIGNMENTS
            SET
                LECTURER_ID = :lecturer_id,
                COURSE_ID = :course_id,
                SEMESTER = :semester,
                ACADEMIC_YEAR = :academic_year,
                PROGRAM_ID = :program_id
            WHERE LECTURER_ID = :original_lecturer_id
              AND COURSE_ID = :original_course_id
              AND SEMESTER = :original_semester
              AND ACADEMIC_YEAR = :original_academic_year
              AND PROGRAM_ID = :original_program_id
            """;
        AddAssignmentParameters(command, request);
        AddOriginalParameters(command, original);

        var updated = await command.ExecuteNonQueryAsync(cancellationToken) == 1;
        await CompleteAsync(transaction, updated, cancellationToken);
        return updated;
    }

    public async Task<bool> DeleteAsync(
        TeachingAssignmentDto assignment,
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
            DELETE FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS
            WHERE LECTURER_ID = :original_lecturer_id
              AND COURSE_ID = :original_course_id
              AND SEMESTER = :original_semester
              AND ACADEMIC_YEAR = :original_academic_year
              AND PROGRAM_ID = :original_program_id
            """;
        AddOriginalParameters(command, assignment);

        var deleted = await command.ExecuteNonQueryAsync(cancellationToken) == 1;
        await CompleteAsync(transaction, deleted, cancellationToken);
        return deleted;
    }

    private static int ReadInt32(IDataRecord reader, string name)
    {
        return Convert.ToInt32(reader.GetDecimal(reader.GetOrdinal(name)));
    }

    private static void AddAssignmentParameters(
        OracleCommand command,
        SaveTeachingAssignmentRequest request)
    {
        command.Parameters.Add("lecturer_id", OracleDbType.Varchar2).Value =
            request.LecturerId.Trim().ToUpperInvariant();
        command.Parameters.Add("course_id", OracleDbType.Varchar2).Value =
            request.CourseId.Trim().ToUpperInvariant();
        command.Parameters.Add("semester", OracleDbType.Int32).Value =
            request.Semester;
        command.Parameters.Add("academic_year", OracleDbType.Int32).Value =
            request.AcademicYear;
        command.Parameters.Add("program_id", OracleDbType.Varchar2).Value =
            request.ProgramId.Trim().ToUpperInvariant();
    }

    private static void AddOriginalParameters(
        OracleCommand command,
        TeachingAssignmentDto assignment)
    {
        command.Parameters.Add(
            "original_lecturer_id",
            OracleDbType.Varchar2).Value = assignment.LecturerId;
        command.Parameters.Add(
            "original_course_id",
            OracleDbType.Varchar2).Value = assignment.CourseId;
        command.Parameters.Add(
            "original_semester",
            OracleDbType.Int32).Value = assignment.Semester;
        command.Parameters.Add(
            "original_academic_year",
            OracleDbType.Int32).Value = assignment.AcademicYear;
        command.Parameters.Add(
            "original_program_id",
            OracleDbType.Varchar2).Value = assignment.ProgramId;
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
