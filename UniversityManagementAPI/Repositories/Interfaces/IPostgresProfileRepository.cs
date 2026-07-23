// UpdateContactRequest and ProfileDto are in the global namespace

namespace UniversityManagementAPI.Repositories.Interfaces;

public interface IPostgresProfileRepository
{
    Task<ProfileDto?> GetStaffProfileAsync(
        string staffId,
        CancellationToken cancellationToken = default);

    Task<ProfileDto?> GetStudentProfileAsync(
        string studentId,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateContactAsync(
        string identityType,
        string identityId,
        UpdateContactRequest request,
        CancellationToken cancellationToken = default);
}
