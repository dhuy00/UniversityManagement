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

    Task<bool> UpdateScoresAsync(
        UpdateEnrollmentScoresRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<RegistrationOptionDto>> GetRegistrationOptionsAsync(
        CancellationToken cancellationToken);

    Task CreateAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken);

    Task<bool> DeleteAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken);
}
