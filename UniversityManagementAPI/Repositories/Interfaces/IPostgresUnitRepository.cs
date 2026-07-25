namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresUnitRepository
{
    Task<IReadOnlyList<UnitDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task CreateAsync(
        CreateUnitRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateAsync(
        string unitId,
        UpdateUnitRequest request,
        CancellationToken cancellationToken = default);
}