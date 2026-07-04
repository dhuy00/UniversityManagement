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
}
