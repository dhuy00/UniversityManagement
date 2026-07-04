public interface IProfileRepository
{
    Task<ProfileDto?> GetStaffProfileAsync(
        string staffId,
        CancellationToken cancellationToken);

    Task<ProfileDto?> GetStudentProfileAsync(
        string studentId,
        CancellationToken cancellationToken);

    Task<bool> UpdateContactAsync(
        string identityType,
        string identityId,
        UpdateContactRequest request,
        CancellationToken cancellationToken);
}
