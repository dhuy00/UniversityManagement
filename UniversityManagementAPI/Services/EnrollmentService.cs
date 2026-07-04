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
}
