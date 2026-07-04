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

    public Task CreateAsync(
        SaveCourseRequest request,
        CancellationToken cancellationToken)
    {
        return _courseRepository.CreateAsync(request, cancellationToken);
    }

    public Task<bool> UpdateAsync(
        string courseId,
        SaveCourseRequest request,
        CancellationToken cancellationToken)
    {
        return _courseRepository.UpdateAsync(
            courseId,
            request,
            cancellationToken);
    }
}
