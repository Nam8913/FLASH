using System.Net;
using System.Text.Json;

public class ServerHost
{
    private HttpListener _listener;
    private readonly int _port;
    private bool _isRunning;

    private DateTime _severStartTime;
    private DateTime _lastRequestTime;

    public ServerHost(FlashConfig config)
    {
        _port = config.port;
        Settings.Instance.WorkingDirectory = config.workingDirectory;

        _listener = new HttpListener();
        _listener.Prefixes.Add($"http://localhost:{_port}/");
    }

    public void Start()
    {
        _severStartTime = DateTime.Now;
        _isRunning = true;
        _listener.Start();
        Log("INFO", $"Listening on http://localhost:{_port}");
        Task.Run(Listen);
    }

    public void Stop()
    {
        _isRunning = false;
        _listener.Stop();
    }

    private async Task Listen()
    {
        while (_isRunning)
        {
            try
            {
                Log("INFO", "Waiting for incoming requests...");
                var context = await _listener.GetContextAsync();
                HandleRequest(context);
            }
            catch (System.Exception exception)
            {
                Log("ERR", exception.Message);
                Log("ERR", exception.StackTrace ?? "No stack trace available.");
                if(Settings.Instance.AutoExitWhenCatchError)
                {
                    Log("WARN", "Auto exiting due to error...");
                    Stop();
                    Environment.Exit(1);
                }
                return;
            }
        }
    }

    private void HandleRequest(HttpListenerContext ctx)
    {
        if (ctx.Request.HttpMethod != "POST")
        {
            ctx.Response.StatusCode = 405;
            ctx.Response.ContentType = "application/json";
            using var writer = new StreamWriter(ctx.Response.OutputStream);
            writer.Write(JsonSerializer.Serialize(new { ok = false, error = "Method Not Allowed" }));
            ctx.Response.Close();
            return;
        }

        _lastRequestTime = DateTime.Now;

        using var reader = new StreamReader(ctx.Request.InputStream);
        var body = reader.ReadToEnd();

        var request = JsonSerializer.Deserialize<DataTransferObj>(body);

        if (request == null)
        {
            ctx.Response.StatusCode = 400;
            ctx.Response.Close();
            return;
        }

        if (!RequestHandlerDict.TryHandleRequest(request))
        {
            Log("ERR", $"No handler for request type: {request.type} from path: {request.path}");
        }else
        {
            Log("INFO", $"Handled request type: {request.type} from path: {request.path}");
        }

        object responseBody;
        if (request.type == "poll")
        {
            var messages = ServerCommandQueue.DequeueMany(10);
            responseBody = new
            {
                ok = true,
                serverUnix = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
                messages
            };
        }
        else
        {
            responseBody = new { ok = true };
        }

        var json = JsonSerializer.Serialize(responseBody);
        ctx.Response.StatusCode = 200;
        ctx.Response.ContentType = "application/json";
        using (var writer = new StreamWriter(ctx.Response.OutputStream))
        {
            writer.Write(json);
        }
        ctx.Response.Close();
    }
    public static void Log(string level, string msg)
    {
        Console.ForegroundColor = level switch
        {
            "INFO" => ConsoleColor.White,
            "WARN" => ConsoleColor.Yellow,
            "ERR"  => ConsoleColor.Red,
            _ => ConsoleColor.Gray
        };

        Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] [{level}] {msg}");
        Console.ResetColor();
    }
}

