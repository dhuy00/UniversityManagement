public interface IUnitService
{
    Task<IReadOnlyList<UnitDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
