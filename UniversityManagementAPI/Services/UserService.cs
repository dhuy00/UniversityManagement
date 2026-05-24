public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;

    public UserService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<List<UserDto>> GetAllUsersAsync()
    {
        // business logic
        var users = await _userRepository.GetAllUsersAsync();

        return users;
    }

    public async Task<List<UserPrivilegeDto>> GetUserPrivilege(string username)
    {
        var privileges = await _userRepository.GetUserPrivilege(username);

        return privileges;
    }
}