public class TableMetadataDto
{
    public string Owner { get; set; } = string.Empty;
    public string TableName { get; set; } = string.Empty;
    public List<string> Columns { get; set; } = [];
}
