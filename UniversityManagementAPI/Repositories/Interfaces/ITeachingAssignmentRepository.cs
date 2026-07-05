public interface ITeachingAssignmentRepository
{
    Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken);

    Task CreateAsync(
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken);

    Task<bool> UpdateAsync(
        TeachingAssignmentDto original,
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken);

    Task<bool> DeleteAsync(
        TeachingAssignmentDto assignment,
        CancellationToken cancellationToken);
}
