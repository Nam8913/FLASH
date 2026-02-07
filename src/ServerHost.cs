using System.Net;
using System.Text.Json;

public class ServerHost
{
    private HttpListener _listener;
    private readonly int _port;
    private bool _isRunning;

    private DateTime _severStartTime;
    private DateTime _lastRequestTime;

    public ServerHost(int port)
    {
        _port = port;
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
            ctx.Response.Close();
            return;
        }

        _lastRequestTime = DateTime.Now;

        using var reader = new StreamReader(ctx.Request.InputStream);
        var body = reader.ReadToEnd();

        var request = JsonSerializer.Deserialize<HTTPRequest>(body);

        if (request == null)
        {
            ctx.Response.StatusCode = 400;
            ctx.Response.Close();
            return;
        }

        switch (request.type)
        {
            case "ping":
                Log("INFO", "Ping from Roblox");
                break;

            case "sync_script":
                Log("INFO", $"Sync script → {request.path}");
                Log("INFO", request.content.Replace("\n", "\\n"));
                break;

            default:
                Log("WARN", $"Unknown message: {request.type}");
                break;
        }

        ctx.Response.StatusCode = 200;
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

