public interface ICoursePlanService
{
    Task<IReadOnlyList<CoursePlanDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
