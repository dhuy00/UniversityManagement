public interface IUnitService
{
    Task<IReadOnlyList<UnitDto>> GetAllAsync(
        CancellationToken cancellationToken);

    Task CreateAsync(
        CreateUnitRequest request,
        CancellationToken cancellationToken);

    Task<bool> UpdateAsync(
        string unitId,
        UpdateUnitRequest request,
        CancellationToken cancellationToken);
}
