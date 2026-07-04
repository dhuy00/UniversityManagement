public sealed class ProfileService : IProfileService
{
    private readonly IProfileRepository _profileRepository;

    public ProfileService(IProfileRepository profileRepository)
    {
        _profileRepository = profileRepository;
    }

    public Task<ProfileDto?> GetProfileAsync(
        string identityType,
        string identityId,
        CancellationToken cancellationToken)
    {
        return identityType switch
        {
            "STAFF" => _profileRepository.GetStaffProfileAsync(
                identityId,
                cancellationToken),
            "STUDENT" => _profileRepository.GetStudentProfileAsync(
                identityId,
                cancellationToken),
            _ => Task.FromResult<ProfileDto?>(null)
        };
    }

    public Task<bool> UpdateContactAsync(
        string identityType,
        string identityId,
        UpdateContactRequest request,
        CancellationToken cancellationToken)
    {
        return _profileRepository.UpdateContactAsync(
            identityType,
            identityId,
            request,
            cancellationToken);
    }
}
