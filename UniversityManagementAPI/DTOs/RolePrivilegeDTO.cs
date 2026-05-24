public class RolePrivilegeDto
{
    public string Role { get; set; } = string.Empty;
    public string Owner { get; set; } = string.Empty;
    public string TableName { get; set; } = string.Empty;
    public string Privilege { get; set; } = string.Empty;
    public string Grantable { get; set; } = string.Empty;
}