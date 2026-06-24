public interface IUserRepository
{
    Task<List<UserDto>> GetAllUsersAsync();
    Task<List<UserPrivilegeDto>> GetUserPrivilege(string username);
    Task<ApiResponse<object>> CreateUser(string username, string password);
    Task<ApiResponse<object>> UpdateUserStatus(string username, string status);
    Task<ApiResponse<object>> UpdateUserPassword(string username, string password);
    Task<ApiResponse<object>> DeleteUser(string username);
    Task<ApiResponse<object>> RevokeUserPrivilege(string username, string privilege, string? table_name = null);
}
