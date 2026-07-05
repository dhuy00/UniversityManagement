public sealed class TeachingAssignmentService : ITeachingAssignmentService
{
    private readonly ITeachingAssignmentRepository _assignmentRepository;

    public TeachingAssignmentService(
        ITeachingAssignmentRepository assignmentRepository)
    {
        _assignmentRepository = assignmentRepository;
    }

    public Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        return _assignmentRepository.GetAllAsync(cancellationToken);
    }

    public Task CreateAsync(
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken)
    {
        return _assignmentRepository.CreateAsync(request, cancellationToken);
    }

    public Task<bool> UpdateAsync(
        TeachingAssignmentDto original,
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken)
    {
        return _assignmentRepository.UpdateAsync(
            original,
            request,
            cancellationToken);
    }

    public Task<bool> DeleteAsync(
        TeachingAssignmentDto assignment,
        CancellationToken cancellationToken)
    {
        return _assignmentRepository.DeleteAsync(
            assignment,
            cancellationToken);
    }
}
