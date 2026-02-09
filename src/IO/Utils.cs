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
}