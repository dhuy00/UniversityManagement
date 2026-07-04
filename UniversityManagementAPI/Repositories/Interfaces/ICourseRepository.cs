public interface ICourseRepository
{
    Task<IReadOnlyList<CourseDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
