namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresStudentRepository
{
    Task<PagedResult<StudentDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default);

    Task CreateAsync(
        CreateStudentRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateAsync(
        string studentId,
        UpdateStudentRequest request,
        CancellationToken cancellationToken = default);
}