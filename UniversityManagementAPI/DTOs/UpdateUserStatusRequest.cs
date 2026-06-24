namespace UniversityManagementAPI.DTOs.Requests;

public class UpdateUserStatusRequest
{
    public string Username { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;
}
