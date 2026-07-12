using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Oracle.ManagedDataAccess.Client;

public sealed class OracleExceptionHandler : IExceptionHandler
{
    private readonly ILogger<OracleExceptionHandler> _logger;

    public OracleExceptionHandler(ILogger<OracleExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        if (exception is not OracleException oracleException)
        {
            return false;
        }

        var error = Map(oracleException.Number);
        _logger.LogWarning(
            "Oracle request rejected with error {OracleErrorNumber} and API code {ApiErrorCode}.",
            oracleException.Number,
            error.Code);

        httpContext.Response.StatusCode = error.StatusCode;
        httpContext.Response.ContentType = "application/problem+json";
        await httpContext.Response.WriteAsJsonAsync(
            new ProblemDetails
            {
                Status = error.StatusCode,
                Title = error.Title,
                Detail = error.Detail,
                Type = $"https://httpstatuses.com/{error.StatusCode}",
                Extensions =
                {
                    ["code"] = error.Code,
                    ["traceId"] = httpContext.TraceIdentifier
                }
            },
            cancellationToken);

        return true;
    }

    private static OracleApiError Map(int number)
    {
        return number switch
        {
            1 => Conflict(
                "duplicate_resource",
                "A record with the same key already exists."),

            2291 => Conflict(
                "referenced_record_missing",
                "A referenced record does not exist."),

            2292 => Conflict(
                "record_in_use",
                "The record is still referenced by other data."),

            1400 or 1438 or 12899 or 2290 => BadRequest(
                "invalid_data",
                "The submitted data violates a database constraint."),

            942 or 1031 or 28115 => Forbidden(
                "database_access_denied",
                "The current identity is not allowed to perform this operation."),

            20501 => Conflict(
                "lecturer_identity_missing",
                "The selected lecturer does not have a staff security identity."),

            20502 => Conflict(
                "invalid_teaching_role",
                "The selected staff member does not have a teaching role."),

            20503 => Conflict(
                "student_identity_missing",
                "The selected student does not have a student security identity."),

            20504 => Conflict(
                "enrollment_program_mismatch",
                "The enrollment program does not match the student program."),

            20505 => Forbidden(
                "enrollment_operation_denied",
                "The current role cannot add or remove enrollments."),

            20506 => Conflict(
                "registration_window_closed",
                "The enrollment adjustment period is closed."),

            20602 => BadRequest(
                "invalid_unit_head",
                "The head must exist and have the Unit Head or Dean role."),

            _ => InternalServerError()
        };
    }

    private static OracleApiError BadRequest(string code, string detail) =>
        new(StatusCodes.Status400BadRequest, code, "Invalid request", detail);

    private static OracleApiError Forbidden(string code, string detail) =>
        new(StatusCodes.Status403Forbidden, code, "Operation forbidden", detail);

    private static OracleApiError Conflict(string code, string detail) =>
        new(StatusCodes.Status409Conflict, code, "Operation conflict", detail);

    private static OracleApiError InternalServerError() =>
        new(
            StatusCodes.Status500InternalServerError,
            "database_error",
            "Database operation failed",
            "An unexpected database error occurred.");

    private sealed record OracleApiError(
        int StatusCode,
        string Code,
        string Title,
        string Detail);
}
