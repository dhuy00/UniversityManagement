public sealed class CoursePlanService : ICoursePlanService
{
    private readonly ICoursePlanRepository _coursePlanRepository;

    public CoursePlanService(ICoursePlanRepository coursePlanRepository)
    {
        _coursePlanRepository = coursePlanRepository;
    }

    public Task<IReadOnlyList<CoursePlanDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        return _coursePlanRepository.GetAllAsync(cancellationToken);
    }

    public Task CreateAsync(
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken)
    {
        return _coursePlanRepository.CreateAsync(request, cancellationToken);
    }

    public Task<bool> UpdateAsync(
        string originalCourseId,
        int originalSemester,
        int originalAcademicYear,
        string originalProgramId,
        SaveCoursePlanRequest request,
        CancellationToken cancellationToken)
    {
        return _coursePlanRepository.UpdateAsync(
            originalCourseId,
            originalSemester,
            originalAcademicYear,
            originalProgramId,
            request,
            cancellationToken);
    }
}
