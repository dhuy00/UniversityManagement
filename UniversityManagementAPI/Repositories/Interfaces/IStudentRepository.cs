public interface IStudentRepository
{
    Task<PagedResult<StudentDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken);
}
