public interface IStudentService
{
    Task<PagedResult<StudentDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken);

    Task CreateAsync(
        CreateStudentRequest request,
        CancellationToken cancellationToken);

    Task<bool> UpdateAsync(
        string studentId,
        UpdateStudentRequest request,
        CancellationToken cancellationToken);
}
