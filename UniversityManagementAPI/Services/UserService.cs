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

    public async Task<ApiResponse<object>> CreateUser(string username, string password)
    {
        return await _userRepository.CreateUser(username, password);
    }

    public string TransformPrivileges(string[] privileges)
    {
        if (privileges == null || privileges.Length == 0)
        {
            throw new ArgumentException("At least one privilege is required.", nameof(privileges));
        }

        return string.Join(", ", privileges);
    }
}