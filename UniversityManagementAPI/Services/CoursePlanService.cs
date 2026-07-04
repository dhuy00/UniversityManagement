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
}
