public static class UniversityIdentityValidator
{
    private static readonly HashSet<string> StaffRoles =
        new(StringComparer.Ordinal)
        {
            "BASIC_STAFF",
            "LECTURER",
            "ACADEMIC_AFFAIRS",
            "UNIT_HEAD",
            "DEAN"
        };

    public static bool IsTrusted(AuthenticatedUser user)
    {
        if (string.IsNullOrWhiteSpace(user.Username) ||
            string.IsNullOrWhiteSpace(user.CampusId))
        {
            return false;
        }

        return user.IdentityType switch
        {
            "STAFF" =>
                StaffRoles.Contains(user.RoleCode) &&
                !string.IsNullOrWhiteSpace(user.StaffId) &&
                string.IsNullOrWhiteSpace(user.StudentId) &&
                !string.IsNullOrWhiteSpace(user.UnitId),

            "STUDENT" =>
                user.RoleCode == "STUDENT" &&
                string.IsNullOrWhiteSpace(user.StaffId) &&
                !string.IsNullOrWhiteSpace(user.StudentId) &&
                string.IsNullOrWhiteSpace(user.UnitId) &&
                !string.IsNullOrWhiteSpace(user.ProgramId) &&
                !string.IsNullOrWhiteSpace(user.MajorId),

            _ => false
        };
    }
}
