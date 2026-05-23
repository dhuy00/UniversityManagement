using Oracle.ManagedDataAccess.Client;

public interface IDbConnectionFactory
{
    OracleConnection CreateConnection();
}