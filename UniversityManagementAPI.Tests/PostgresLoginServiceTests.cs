public sealed class PostgresLoginServiceTests
{
    [Fact]
    public async Task AuthenticateAsync_MapsTrustedStaffIdentity()
    {
        var candidate = CreateStaffCandidate();
        var verifier = new RecordingPasswordVerifier(result: true);
        var service = CreateService(candidate, verifier);

        var result = await service.AuthenticateAsync(
            "basic01",
            "correct-password",
            CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal(candidate.UserId, result.UserId);
        Assert.Equal(candidate.Username, result.User.Username);
        Assert.Equal("STAFF", result.User.IdentityType);
        Assert.Equal("BASIC_STAFF", result.User.RoleCode);
        Assert.Equal(candidate.StaffId, result.User.StaffId);
        Assert.Equal(candidate.UnitId, result.User.UnitId);
        Assert.Equal(candidate.CampusId, result.User.CampusId);
        Assert.Equal(candidate.PasswordHash, verifier.LastHash);
    }

    [Fact]
    public async Task AuthenticateAsync_MapsTrustedStudentIdentity()
    {
        var candidate = CreateStudentCandidate();
        var service = CreateService(
            candidate,
            new RecordingPasswordVerifier(result: true));

        var result = await service.AuthenticateAsync(
            candidate.Username,
            "correct-password",
            CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal("STUDENT", result.User.IdentityType);
        Assert.Equal("STUDENT", result.User.RoleCode);
        Assert.Equal(candidate.StudentId, result.User.StudentId);
        Assert.Equal(candidate.ProgramId, result.User.ProgramId);
        Assert.Equal(candidate.MajorId, result.User.MajorId);
    }

    [Fact]
    public async Task AuthenticateAsync_RejectsWrongPassword()
    {
        var service = CreateService(
            CreateStaffCandidate(),
            new RecordingPasswordVerifier(result: false));

        Assert.Null(await service.AuthenticateAsync(
            "BASIC01",
            "wrong-password",
            CancellationToken.None));
    }

    [Fact]
    public async Task AuthenticateAsync_UsesDummyHashForUnknownOrInactiveUser()
    {
        var verifier = new RecordingPasswordVerifier(result: false);
        var service = CreateService(candidate: null, verifier);

        Assert.Null(await service.AuthenticateAsync(
            "UNKNOWN01",
            "any-password",
            CancellationToken.None));
        Assert.StartsWith("$2a$12$", verifier.LastHash);
    }

    [Theory]
    [InlineData("missing")]
    [InlineData("multiple")]
    [InlineData("duplicate")]
    public async Task AuthenticateAsync_RejectsInvalidRoleCardinality(string scenario)
    {
        var roleCodes = scenario switch
        {
            "missing" => Array.Empty<string>(),
            "multiple" => ["BASIC_STAFF", "DEAN"],
            "duplicate" => ["BASIC_STAFF", "BASIC_STAFF"],
            _ => throw new ArgumentOutOfRangeException(nameof(scenario))
        };
        var candidate = CreateStaffCandidate() with { RoleCodes = roleCodes };
        var service = CreateService(
            candidate,
            new RecordingPasswordVerifier(result: true));

        var result = await service.AuthenticateAsync(
            candidate.Username,
            "correct-password",
            CancellationToken.None);

        if (scenario == "duplicate")
        {
            Assert.NotNull(result);
        }
        else
        {
            Assert.Null(result);
        }
    }

    [Fact]
    public async Task AuthenticateAsync_RejectsMalformedIdentity()
    {
        var candidate = CreateStaffCandidate() with
        {
            IdentityType = null,
            StaffId = null,
            UnitId = null
        };
        var service = CreateService(
            candidate,
            new RecordingPasswordVerifier(result: true));

        Assert.Null(await service.AuthenticateAsync(
            candidate.Username,
            "correct-password",
            CancellationToken.None));
    }

    [Fact]
    public async Task AuthenticateAsync_RejectsRoleIdentityMismatch()
    {
        var candidate = CreateStudentCandidate() with
        {
            RoleCodes = ["DEAN"]
        };
        var service = CreateService(
            candidate,
            new RecordingPasswordVerifier(result: true));

        Assert.Null(await service.AuthenticateAsync(
            candidate.Username,
            "correct-password",
            CancellationToken.None));
    }

    private static PostgresLoginService CreateService(
        PostgresAuthenticationCandidate? candidate,
        RecordingPasswordVerifier verifier) => new(
            new StubAuthRepository(candidate),
            verifier);

    private static PostgresAuthenticationCandidate CreateStaffCandidate() => new(
        101,
        "BASIC01",
        "$2a$12$R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW",
        ["BASIC_STAFF"],
        "STAFF",
        "ST_BASIC01",
        null,
        "UNIT_IS",
        null,
        null,
        "CAMPUS_MAIN");

    private static PostgresAuthenticationCandidate CreateStudentCandidate() => new(
        202,
        "STUDENT01",
        "$2a$12$R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW",
        ["STUDENT"],
        "STUDENT",
        null,
        "SV0001",
        null,
        "PROGRAM_IT",
        "MAJOR_SE",
        "CAMPUS_MAIN");

    private sealed class StubAuthRepository(
        PostgresAuthenticationCandidate? candidate) : IPostgresAuthRepository
    {
        public Task<PostgresAuthenticationCandidate?> FindActiveByUsernameAsync(
            string username,
            CancellationToken cancellationToken) => Task.FromResult(candidate);
    }

    private sealed class RecordingPasswordVerifier(bool result) : IPasswordVerifier
    {
        public string? LastHash { get; private set; }

        public bool Verify(string? password, string? passwordHash)
        {
            LastHash = passwordHash;
            return result;
        }
    }
}
