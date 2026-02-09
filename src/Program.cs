namespace FLASH
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Program program = new Program();

            for (int i = 0; i < args.Length; i++)
            {
                System.Console.WriteLine($"Argument {i}: {args[i]}");
            }
            
            program._config = FlashConfig.LoadOrCreateConfig();
            
            while (!FlashConfig.ValidateConfig(program._config))
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Please fix the above issues in FLASH.json and restart FLASH.exe.");
                Console.ResetColor();
                Thread.Sleep(5000);
            }

            program._serverHost = new ServerHost(program._config);
            program._serverHost.Start();
            
            Console.CancelKeyPress += (_, e) =>
            {
                System.Console.WriteLine("Shutting down server...");
                program._serverHost.Stop();
                Environment.Exit(0);
            };

            Thread.Sleep(Timeout.Infinite);
        }

        public ServerHost? _serverHost;
        public FlashConfig? _config;
    }
}
