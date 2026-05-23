public interface IUserRepository
{
    Task<List<UserDto>> GetAllUsersAsync();
}