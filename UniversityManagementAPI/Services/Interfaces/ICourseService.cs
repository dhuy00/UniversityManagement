public interface ICourseService
{
    Task<IReadOnlyList<CourseDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
