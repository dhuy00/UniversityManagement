public sealed class StudentService : IStudentService
{
    private readonly IStudentRepository _studentRepository;

    public StudentService(IStudentRepository studentRepository)
    {
        _studentRepository = studentRepository;
    }

    public Task<PagedResult<StudentDto>> GetPageAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken)
    {
        return _studentRepository.GetPageAsync(
            page,
            pageSize,
            search,
            cancellationToken);
    }
}
