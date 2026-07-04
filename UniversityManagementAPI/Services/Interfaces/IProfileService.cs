public interface IProfileService
{
    Task<ProfileDto?> GetProfileAsync(
        string identityType,
        string identityId,
        CancellationToken cancellationToken);

    Task<bool> UpdateContactAsync(
        string identityType,
        string identityId,
        UpdateContactRequest request,
        CancellationToken cancellationToken);
}
