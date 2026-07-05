public sealed class EnrollmentService : IEnrollmentService
{
    private readonly IEnrollmentRepository _enrollmentRepository;

    public EnrollmentService(IEnrollmentRepository enrollmentRepository)
    {
        _enrollmentRepository = enrollmentRepository;
    }

    public Task<IReadOnlyList<EnrollmentDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        return _enrollmentRepository.GetAllAsync(cancellationToken);
    }

    public Task<IReadOnlyList<EnrollmentDto>> GetByCoursePlanAsync(
        string courseId,
        int semester,
        int academicYear,
        string programId,
        CancellationToken cancellationToken)
    {
        return _enrollmentRepository.GetByCoursePlanAsync(
            courseId,
            semester,
            academicYear,
            programId,
            cancellationToken);
    }

    public Task<bool> UpdateScoresAsync(
        UpdateEnrollmentScoresRequest request,
        CancellationToken cancellationToken)
    {
        return _enrollmentRepository.UpdateScoresAsync(
            request,
            cancellationToken);
    }

    public Task<IReadOnlyList<RegistrationOptionDto>>
        GetRegistrationOptionsAsync(CancellationToken cancellationToken)
    {
        return _enrollmentRepository.GetRegistrationOptionsAsync(
            cancellationToken);
    }

    public Task CreateAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken)
    {
        return _enrollmentRepository.CreateAsync(request, cancellationToken);
    }

    public Task<bool> DeleteAsync(
        MaintainEnrollmentRequest request,
        CancellationToken cancellationToken)
    {
        return _enrollmentRepository.DeleteAsync(request, cancellationToken);
    }
}
