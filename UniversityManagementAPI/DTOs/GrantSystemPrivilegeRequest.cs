namespace UniversityManagementAPI.DTOs.Requests;

public class GrantSystemPrivilegeRequest
{
    public string PrivilegeName { get; set; } = string.Empty;

    public string Target { get; set; } = string.Empty;
}
