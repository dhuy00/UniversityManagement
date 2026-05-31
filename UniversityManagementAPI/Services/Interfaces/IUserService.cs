public interface IUserService
{
    Task<List<UserDto>> GetAllUsersAsync();
    Task<List<UserPrivilegeDto>> GetUserPrivilege(string username);
    Task<ApiResponse<object>> CreateUser(string username, string password);
    string TransformPrivileges(string[] privileges);
}