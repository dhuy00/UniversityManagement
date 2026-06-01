namespace UniversityManagementAPI.DTOs.Requests;
using System.Text.Json.Serialization;

public class RevokeRolePrivilegeRequest
{
    [JsonPropertyName("rolename")]
    public string Rolename { get; set; } = string.Empty;

    [JsonPropertyName("table_name")]
    public string TableName { get; set; } = string.Empty;

    [JsonPropertyName("privilege")]
    public string[] Privilege { get; set; } = [];
}