public sealed class UnitService : IUnitService
{
    private readonly IUnitRepository _unitRepository;

    public UnitService(IUnitRepository unitRepository)
    {
        _unitRepository = unitRepository;
    }

    public Task<IReadOnlyList<UnitDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        return _unitRepository.GetAllAsync(cancellationToken);
    }
}
