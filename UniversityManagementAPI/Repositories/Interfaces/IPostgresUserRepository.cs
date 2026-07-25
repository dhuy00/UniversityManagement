using UniversityManagementAPI.DTOs.Requests;

public interface IPostgresUserRepository
{
    Task<PagedResult<UserDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> CreateUserAsync(
        CreateUserRequest request,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> UpdateUserStatusAsync(
        string username,
        bool isActive,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> UpdateUserPasswordAsync(
        string username,
        string newPasswordHash,
        CancellationToken cancellationToken = default);
    Task<ApiResponse<object>> DeleteUserAsync(
        string username,
        CancellationToken cancellationToken = default);
}
