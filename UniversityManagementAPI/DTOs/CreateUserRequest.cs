namespace UniversityManagementAPI.DTOs.Requests;

public class CreateUserRequest
{
    public string Username { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;
}