public interface ITeachingAssignmentRepository
{
    Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
