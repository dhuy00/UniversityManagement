public interface ITeachingAssignmentService
{
    Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken);
}
