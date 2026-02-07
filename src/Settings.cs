public sealed class Settings
{
    private static readonly Lazy<Settings> _instance = new(() => new Settings());
    public static Settings Instance => _instance.Value;

    private Settings() { }

    private string workingDirectory = string.Empty;
    private bool autoSyncEnabled = false;
    private bool autoExitWhenCatchError = true;

    public string WorkingDirectory
    {
        get { return workingDirectory; }
        set { workingDirectory = value; }
    }
    public bool AutoSyncEnabled
    {
        get { return autoSyncEnabled; }
        set { autoSyncEnabled = value; }
    }
    public bool AutoExitWhenCatchError
    {
        get { return autoExitWhenCatchError; }
        set { autoExitWhenCatchError = value; }
    }
}