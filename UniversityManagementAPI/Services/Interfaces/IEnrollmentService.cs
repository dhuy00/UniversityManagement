public interface IEnrollmentService
{
    Task<IReadOnlyList<EnrollmentDto>> GetAllAsync(
        CancellationToken cancellationToken);

    Task<IReadOnlyList<EnrollmentDto>> GetByCoursePlanAsync(
        string courseId,
        int semester,
        int academicYear,
        string programId,
        CancellationToken cancellationToken);
}
