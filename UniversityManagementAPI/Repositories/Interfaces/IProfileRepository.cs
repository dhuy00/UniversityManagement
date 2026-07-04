public interface IProfileRepository
{
    Task<ProfileDto?> GetStaffProfileAsync(
        string staffId,
        CancellationToken cancellationToken);

    Task<ProfileDto?> GetStudentProfileAsync(
        string studentId,
        CancellationToken cancellationToken);
}
