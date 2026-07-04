public sealed class CourseService : ICourseService
{
    private readonly ICourseRepository _courseRepository;

    public CourseService(ICourseRepository courseRepository)
    {
        _courseRepository = courseRepository;
    }

    public Task<IReadOnlyList<CourseDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        return _courseRepository.GetAllAsync(cancellationToken);
    }
}
