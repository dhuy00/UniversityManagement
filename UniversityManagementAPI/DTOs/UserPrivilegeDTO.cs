public class UserPrivilegeDto
{
    public string PrivilegeType { get; set; } = string.Empty;
    public string Grantee { get; set; } = string.Empty;
    public string Owner { get; set; } = string.Empty;
    public string TableName { get; set; } = string.Empty;
    public string ColumnName { get; set; } = string.Empty;
    public string Privilege { get; set; } = string.Empty;
    public string Grantable { get; set; } = string.Empty;
}
