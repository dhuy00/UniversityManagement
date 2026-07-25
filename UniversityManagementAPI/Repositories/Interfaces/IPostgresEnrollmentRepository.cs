namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresEnrollmentRepository
{
    Task<IReadOnlyList<EnrollmentDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<EnrollmentDto>> GetByCoursePlanAsync(
        string courseId,
        int semester,
        int academicYear,
        string programId,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateScoresAsync(
        UpdateEnrollmentScoresRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<RegistrationOptionDto>> GetRegistrationOptionsAsync(
        CancellationToken cancellationToken = default);

    Task CreateAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken = default);
}
