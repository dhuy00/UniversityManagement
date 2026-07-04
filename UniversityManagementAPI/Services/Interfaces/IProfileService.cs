public interface IProfileService
{
    Task<ProfileDto?> GetProfileAsync(
        string identityType,
        string identityId,
        CancellationToken cancellationToken);
}
