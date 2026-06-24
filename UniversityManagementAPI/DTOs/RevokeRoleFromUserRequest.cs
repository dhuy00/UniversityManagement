namespace UniversityManagementAPI.DTOs.Requests;

public class RevokeRoleFromUserRequest
{
    public string Username { get; set; } = string.Empty;

    public string Rolename { get; set; } = string.Empty;
}
