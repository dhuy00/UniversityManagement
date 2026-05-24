public interface IUserService
{
    Task<List<UserDto>> GetAllUsersAsync();
    Task<List<UserPrivilegeDto>> GetUserPrivilege(string username);
}