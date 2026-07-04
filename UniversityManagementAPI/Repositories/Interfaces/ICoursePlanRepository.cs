public interface ICoursePlanRepository
{
    Task<IReadOnlyList<CoursePlanDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
