namespace UniversityManagementAPI.DTOs.Requests;

public class CreateRoleRequest
{
    public string Rolename { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;
}