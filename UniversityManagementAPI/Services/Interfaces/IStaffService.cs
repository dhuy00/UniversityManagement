public interface IStaffService
{
    Task<IReadOnlyList<StaffDto>> GetAllAsync(
        CancellationToken cancellationToken);
    Task CreateAsync(
        CreateStaffRequest request,
        CancellationToken cancellationToken);
    Task<bool> UpdateAsync(
        string staffId,
        UpdateStaffRequest request,
        CancellationToken cancellationToken);
    Task<bool> DeleteAsync(
        string staffId,
        CancellationToken cancellationToken);
}
