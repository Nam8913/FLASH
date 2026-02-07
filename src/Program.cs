namespace FLASH
{
    public class Program
    {
        public static void Main(string[] args)
        {
            for (int i = 0; i < args.Length; i++)
            {
                System.Console.WriteLine($"Argument {i}: {args[i]}");
            }

            ServerHost _serverHost = new ServerHost(3000);
            _serverHost.Start();
            
            Console.CancelKeyPress += (_, e) =>
            {
                System.Console.WriteLine("Shutting down server...");
                _serverHost.Stop();
                Environment.Exit(0);
            };

            Thread.Sleep(Timeout.Infinite);
        }
    }
}
