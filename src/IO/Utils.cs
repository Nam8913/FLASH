using System.Text.Json;

public static class Utils
{
    public static void WriteToFile(string path, string content)
    {
        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
        {
            Directory.CreateDirectory(directory);
            System.Console.WriteLine($"Created directory: {directory}");
        }
        File.WriteAllText(path, content);
        System.Console.WriteLine($"Write at: {path}");
    }

    public static void HandleExplorerJSON(string content)
    {
        JsonDocument doc = JsonDocument.Parse(content);
        JsonElement root = doc.RootElement;
        DataNode rootNode = new DataNode().ParseNode(root);

        DirectoryInfo dir = new DirectoryInfo(Settings.Instance.WorkingDirectory);
        //WriteNodeToDisk(rootNode, dir.FullName);
        rootNode.Children.ForEach(child => WriteNodeToDisk(child, dir.FullName));
    }

    public static void WriteLuaScript(string robloxPath, string source)
    {
        if (string.IsNullOrWhiteSpace(robloxPath))
        {
            robloxPath = "UnknownScript";
        }

        var parts = robloxPath
            .Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(SanitizeName)
            .ToArray();

        if (parts.Length == 0)
        {
            parts = new[] { "UnknownScript" };
        }

        var fileName = parts[^1] + ".lua";
        var dirParts = parts.Take(parts.Length - 1).ToArray();

        var dir = Settings.Instance.WorkingDirectory;
        if (dirParts.Length > 0)
        {
            dir = Path.Combine(new[] { dir }.Concat(dirParts).ToArray());
        }

        WriteToFile(Path.Combine(dir, fileName), source ?? string.Empty);
        Console.WriteLine($"Lua script written: {robloxPath} → {Path.Combine(dir, fileName)}");
    }

    private static string SanitizeName(string name)
    {
        foreach (var c in Path.GetInvalidFileNameChars())
        name = name.Replace(c, '_');

    return name;
    }
    private static void WriteNodeToDisk(DataNode node, string outputDir)
    {
        Directory.CreateDirectory(outputDir);

        string safeName = SanitizeName(node.Name);

        // 1. Ghi file json (không có Children)
        var filePath = Path.Combine(outputDir, safeName + ".json");

        DataNode fileData = new DataNode();
        fileData.Name = node.Name;
        fileData.ClassName = node.ClassName;
        fileData.Tags = node.Tags;
        fileData.Attributes = node.Attributes;
        fileData.Properties = node.Properties;

        File.WriteAllText(
            filePath,
            JsonSerializer.Serialize(fileData, new JsonSerializerOptions
            {
                WriteIndented = true
            })
        );

        // 2. Nếu có children → tạo folder + đệ quy
        if (node.Children != null && node.Children.Count > 0)
        {
            var folderPath = Path.Combine(outputDir, safeName);
            Directory.CreateDirectory(folderPath);

            foreach (var child in node.Children)
            {
                WriteNodeToDisk(child, folderPath);
            }
        }
    }

    class DataNode
    {
        public string Name { get; set; }
        public string ClassName { get; set; }
        public HashSet<string> Tags { get; set; }
            = new();
        public Dictionary<string, object> Attributes { get; set; }
            = new();
        public Dictionary<string, object> Properties { get; set; }
            = new();
        public List<DataNode> Children { get; set; }
            = new();

        public DataNode ParseNode(JsonElement element)
        {
            var node = new DataNode
            {
                Name = element.GetProperty("Name").GetString(),
                ClassName = element.GetProperty("ClassName").GetString()
            };
            if(element.TryGetProperty("Tags", out var tags))
            {
                foreach (var tag in tags.EnumerateArray())
                {
                    node.Tags.Add(tag.GetString());
                }
            }
            // Attributes
            if (element.TryGetProperty("Attributes", out var attrs))
            {
                if(attrs.ValueKind != JsonValueKind.Object)
                {
                    // Invalid format, skip
                    goto skip_attrs;
                }
                foreach (var attr in attrs.EnumerateObject())
                {
                    node.Attributes[attr.Name] = ParseJsonValue(attr.Value);
                }
                skip_attrs:;
            }
            // Properties
            if (element.TryGetProperty("Properties", out var props))
            {
                if(props.ValueKind != JsonValueKind.Object)
                {
                    // Invalid format, skip
                    goto skip_props;
                }
                foreach (var prop in props.EnumerateObject())
                {
                    node.Properties[prop.Name] = ParseJsonValue(prop.Value);
                }
                skip_props:;
            }

            // Children (đệ quy)
            if (element.TryGetProperty("Children", out var children))
            {
                foreach (var child in children.EnumerateArray())
                {
                    node.Children.Add(ParseNode(child));
                }
            }

            return node;
        }
        object ParseJsonValue(JsonElement value)
        {
            return value.ValueKind switch
            {
                JsonValueKind.Number => value.GetDouble(),
                JsonValueKind.String => value.GetString(),
                JsonValueKind.True => true,
                JsonValueKind.False => false,

                JsonValueKind.Array => value
                    .EnumerateArray()
                    .Select(ParseJsonValue)
                    .ToList(),

                JsonValueKind.Object => value
                    .EnumerateObject()
                    .ToDictionary(
                        p => p.Name,
                        p => ParseJsonValue(p.Value)
                    ),

                _ => null
            };
        }
    }
    
}