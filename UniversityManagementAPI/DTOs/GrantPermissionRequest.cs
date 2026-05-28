namespace UniversityManagementAPI.DTOs.Requests;
using System.Text.Json.Serialization;

public class GrantPermissionRequest
{
    [JsonPropertyName("permission_type")]
    public string PermissionType { get; set; } = string.Empty;

    [JsonPropertyName("table_name")]
    public string TableName { get; set; } = string.Empty;

    [JsonPropertyName("target")]
    public string Target { get; set; } = string.Empty;

    [JsonPropertyName("is_grant_option")]
    public int IsGrantOption { get; set; } = 0;

    [JsonPropertyName("list_column")]
    public string[] ListColumn { get; set; } = [];
}