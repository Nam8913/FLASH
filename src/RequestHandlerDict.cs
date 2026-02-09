using System.Text.Json;

public static class RequestHandlerDict
{
    private static readonly Dictionary<string, Action<DataTransferObj>> Handlers = new Dictionary<string, Action<DataTransferObj>>()
    {
        { "ping", (request) => ServerHost.Log("INFO", "Ping from Roblox") },
        { "sync_script", (request) => 
            {
                ServerHost.Log("INFO", $"Sync script from: {request.path}");
                ServerHost.Log("INFO", request.content);
                using var doc = JsonDocument.Parse(request.content);
                string pretty = JsonSerializer.Serialize(
                    doc,
                    new JsonSerializerOptions { WriteIndented = true }
                );
                //TEST:
                Utils.WriteToFile(Path.Combine(Settings.Instance.WorkingDirectory, "Test.json"), pretty);
            } 
        }
    };

    public static bool TryHandleRequest(DataTransferObj request)
    {
        if (Handlers.TryGetValue(request.type, out var handler))
        {
            handler(request);
            return true;
        }
        return false;
    }
}