public interface IUserService
{
    Task<List<UserDto>> GetAllUsersAsync();
}