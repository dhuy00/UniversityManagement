public interface IUnitRepository
{
    Task<IReadOnlyList<UnitDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
