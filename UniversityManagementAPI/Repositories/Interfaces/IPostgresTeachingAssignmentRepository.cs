namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresTeachingAssignmentRepository
{
    Task<IReadOnlyList<TeachingAssignmentDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task CreateAsync(
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateAsync(
        TeachingAssignmentDto original,
        SaveTeachingAssignmentRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        TeachingAssignmentDto assignment,
        CancellationToken cancellationToken = default);
}