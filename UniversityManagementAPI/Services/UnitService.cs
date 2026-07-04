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

    public Task<bool> UpdateAsync(
        string unitId,
        UpdateUnitRequest request,
        CancellationToken cancellationToken)
    {
        return _unitRepository.UpdateAsync(
            unitId,
            request,
            cancellationToken);
    }
}
