using System.Text.Json;

public class FlashConfig
{
    public string workingDirectory { get; set; } = string.Empty;
    public int port { get; set; } = 3000;
    const string fileName = "FLASH.json";
    public static FlashConfig LoadOrCreateConfig()
    {
        
        string configFileDir = Path.Combine(
            AppContext.BaseDirectory,
            fileName
        );
        Console.WriteLine($"Config file path: {configFileDir}");
        if (!File.Exists(configFileDir))
        {
            var defaultConfig = new FlashConfig
            {
                workingDirectory = "PUT_YOUR_PROJECT_PATH_HERE",
                port = 3000
            };

            var json = JsonSerializer.Serialize(
                defaultConfig,
                new JsonSerializerOptions { WriteIndented = true }
            );

            File.WriteAllText(configFileDir, json);

            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("FLASH.json not found.");
            Console.WriteLine("A default config has been created.");
            Console.WriteLine($"Please edit {configFileDir} and restart FLASH.exe.");
            Console.ResetColor();

            Environment.Exit(0);
        }

        var content = File.ReadAllText(configFileDir);
        return JsonSerializer.Deserialize<FlashConfig>(content)
            ?? throw new Exception("Failed to load FLASH.json");
    }

    public static bool ValidateConfig(FlashConfig config)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        if (string.IsNullOrWhiteSpace(config.workingDirectory))
        {
            Console.WriteLine("workingDirectory is empty.");
            return false;
        }    

        if (!Directory.Exists(config.workingDirectory))
        {
            Console.WriteLine("workingDirectory does not exist.");
            Console.WriteLine($"current value: {config.workingDirectory}");
            return false;
        }    

        if (config.port < 1024 || config.port > 65535)
        {
            Console.WriteLine("port must be between 1024 and 65535.");
            Console.WriteLine($"current value: {config.port}");
            return false;
        }
        Console.ResetColor();
        return true;
    }
}