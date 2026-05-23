using Oracle.ManagedDataAccess.Client;

public class OracleConnectionFactory : IDbConnectionFactory
{
    private readonly IConfiguration _configuration;

    public OracleConnectionFactory(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public OracleConnection CreateConnection()
    {
        return new OracleConnection(
            _configuration.GetConnectionString("OracleDb"));
    }
}