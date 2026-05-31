namespace UniversityManagementAPI.DTOs.Requests;
using System.Text.Json.Serialization;

public class RevokeUserPrivilegeRequest
{
    [JsonPropertyName("username")]
    public string Username { get; set; } = string.Empty;

    [JsonPropertyName("table_name")]
    public string TableName { get; set; } = string.Empty;

    [JsonPropertyName("privilege")]
    public string[] Privilege { get; set; } = [];
}