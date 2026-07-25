namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresStaffRepository
{
    Task<IReadOnlyList<StaffDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task CreateAsync(
        CreateStaffRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateAsync(
        string staffId,
        UpdateStaffRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        string staffId,
        CancellationToken cancellationToken = default);
}