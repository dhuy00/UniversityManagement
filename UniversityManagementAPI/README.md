# University Management API

## Authentication model

Users sign in with an Oracle demo account created by the SQL installation,
such as `LECTURER01` or `STUDENT01`.

`POST /api/auth/login` validates the credentials by opening an Oracle
connection as that user. The API then:

- Reads trusted `UNIVERSITY_CTX` values initialized by the logon trigger.
- Issues a JWT containing identity metadata and an opaque session identifier.
- Protects the Oracle connection string with ASP.NET Core Data Protection and
  retains it only in the server-side session store.
- Opens repository connections as the authenticated Oracle user so
  `SESSION_USER` and VPD policies remain effective.

The Oracle password is never returned to the browser or embedded in the JWT.
Sessions are currently in process memory, so restarting the API intentionally
invalidates all tokens. Use a protected distributed session store before
running multiple API instances.

Authentication responsibilities are separated as follows:

- `AuthRepository` opens Oracle connections and reads `UNIVERSITY_CTX`.
- `AuthService` coordinates login, server-side session creation, and logout.
- `JwtTokenService` creates signed access tokens.
- `AuthenticationServiceExtensions` owns JWT validation and dependency
  registration, keeping `Program.cs` limited to application composition.

## Configuration

Development defaults to:

```text
Oracle:DataSource = localhost:1521/XEPDB1
Jwt:ExpirationMinutes = 480
```

In Development, the API generates an ephemeral JWT signing key when `Jwt:Key`
is missing or shorter than 32 bytes. Outside Development, provide a secret of
at least 32 bytes:

```powershell
$env:Jwt__Key = "<random secret with at least 32 bytes>"
dotnet run
```

Never configure `SYS`, `SYSTEM`, or `UNIVERSITY_APP` credentials in API
settings. End-user data access must use the authenticated Oracle identity.

## Authentication endpoints

```text
POST /api/auth/login
POST /api/auth/logout
```

Login request:

```json
{
  "username": "LECTURER01",
  "password": "<generated demo-user password>"
}
```
