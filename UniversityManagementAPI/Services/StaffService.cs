public sealed class StaffService : IStaffService
{
    private readonly IStaffRepository _repository;

    public StaffService(IStaffRepository repository)
    {
        _repository = repository;
    }

    public Task<IReadOnlyList<StaffDto>> GetAllAsync(
        CancellationToken cancellationToken) =>
        _repository.GetAllAsync(cancellationToken);

    public Task CreateAsync(
        CreateStaffRequest request,
        CancellationToken cancellationToken) =>
        _repository.CreateAsync(request, cancellationToken);

    public Task<bool> UpdateAsync(
        string staffId,
        UpdateStaffRequest request,
        CancellationToken cancellationToken) =>
        _repository.UpdateAsync(staffId, request, cancellationToken);

    public Task<bool> DeleteAsync(
        string staffId,
        CancellationToken cancellationToken) =>
        _repository.DeleteAsync(staffId, cancellationToken);
}
