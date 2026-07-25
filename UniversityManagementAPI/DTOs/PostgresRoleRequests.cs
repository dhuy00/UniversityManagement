namespace UniversityManagementAPI.DTOs;

public class CreatePostgresRoleRequest
{
    public string RoleCode { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
