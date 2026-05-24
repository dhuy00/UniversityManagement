public interface IUserRepository
{
    Task<List<UserDto>> GetAllUsersAsync();
    Task<List<UserPrivilegeDto>> GetUserPrivilege(string username);
}