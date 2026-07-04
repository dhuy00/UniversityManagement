public interface ICourseRepository
{
    Task<IReadOnlyList<CourseDto>> GetAllAsync(
        CancellationToken cancellationToken);

    Task CreateAsync(
        SaveCourseRequest request,
        CancellationToken cancellationToken);

    Task<bool> UpdateAsync(
        string courseId,
        SaveCourseRequest request,
        CancellationToken cancellationToken);
}
