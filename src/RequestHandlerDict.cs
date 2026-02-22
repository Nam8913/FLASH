using System.Text.Json;
using System.IO;

public static class RequestHandlerDict
{
    private static readonly Dictionary<string, Action<DataTransferObj>> Handlers = new Dictionary<string, Action<DataTransferObj>>()
    {
        { "ping", (request) =>
            {
                ServerHost.Log("INFO", "Ping from Roblox");
                ServerCommandQueue.Enqueue("pong", request.path, "pong from server");
            }
        },
        { "poll", (request) => { } },
        { "push_code", (request) =>
            {
                ServerHost.Log("INFO", "Push code requested (client will upload via sync_lua)");
                ServerCommandQueue.Enqueue("push_ack", "", "ok");
            }
        },
        { "pull_code", (request) =>
            {
                ServerHost.Log("INFO", "Pull code requested (server will send apply_lua messages)");

                var baseDir = Settings.Instance.WorkingDirectory;
                if (string.IsNullOrWhiteSpace(baseDir) || !Directory.Exists(baseDir))
                {
                    ServerHost.Log("WARN", $"WorkingDirectory not found: {baseDir}");
                    ServerCommandQueue.Enqueue("pull_done", "", "0");
                    return;
                }

                var sent = 0;
                const int maxScriptsPerPull = 500;
                foreach (var file in Directory.EnumerateFiles(baseDir, "*.lua", SearchOption.AllDirectories))
                {
                    if (sent >= maxScriptsPerPull)
                    {
                        ServerHost.Log("WARN", $"Pull truncated at {maxScriptsPerPull} scripts");
                        break;
                    }

                    string rel = Path.GetRelativePath(baseDir, file);
                    var dir = Path.GetDirectoryName(rel) ?? string.Empty;
                    var fileName = Path.GetFileName(rel);

                    string objectType = string.Empty;
                    string leafName = fileName;

                    if (fileName.EndsWith(".server.lua", StringComparison.OrdinalIgnoreCase))
                    {
                        objectType = "server.lua";
                        leafName = fileName[..^".server.lua".Length];
                    }
                    else if (fileName.EndsWith(".client.lua", StringComparison.OrdinalIgnoreCase))
                    {
                        objectType = "client.lua";
                        leafName = fileName[..^".client.lua".Length];
                    }
                    else if (fileName.EndsWith(".module.lua", StringComparison.OrdinalIgnoreCase))
                    {
                        objectType = "module.lua";
                        leafName = fileName[..^".module.lua".Length];
                    }
                    else if (fileName.EndsWith(".lua", StringComparison.OrdinalIgnoreCase))
                    {
                        leafName = fileName[..^".lua".Length];
                    }

                    var robloxPath = string.IsNullOrEmpty(dir)
                        ? leafName
                        : (dir.Replace(Path.DirectorySeparatorChar, '/') + "/" + leafName);

                    var content = File.ReadAllText(file);
                    ServerCommandQueue.Enqueue("apply_lua", robloxPath, content, objectType);
                    sent++;
                }

                ServerCommandQueue.Enqueue("pull_done", "", sent.ToString());
            }
        },
        { "sync_lua", (request) =>
            {
                ServerHost.Log("INFO", $"Sync lua from: {request.path}");
                Utils.WriteLuaScript(request.path, request.content, request.objectType);
            }
        },
        { "sync_explorer", (request) => 
            {
                ServerHost.Log("INFO", $"Sync explorer from: {request.path}");
                ServerHost.Log("INFO", request.content);
                using var doc = JsonDocument.Parse(request.content);
                string pretty = JsonSerializer.Serialize(
                    doc,
                    new JsonSerializerOptions { WriteIndented = true }
                );
                //TEST:
                Utils.WriteToFile(Path.Combine(Settings.Instance.WorkingDirectory, "Test.json"), pretty);
                Utils.HandleExplorerJSON(request.content);
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