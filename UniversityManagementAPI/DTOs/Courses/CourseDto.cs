public sealed class CourseDto
{
    public string CourseId { get; init; } = string.Empty;
    public string CourseName { get; init; } = string.Empty;
    public int Credits { get; init; }
    public int TheoryPeriods { get; init; }
    public int PracticePeriods { get; init; }
    public int MaxStudents { get; init; }
    public string UnitId { get; init; } = string.Empty;
}
