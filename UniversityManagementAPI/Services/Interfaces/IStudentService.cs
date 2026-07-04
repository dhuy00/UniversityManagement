public interface IStudentService
{
    Task<PagedResult<StudentDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken);
}
