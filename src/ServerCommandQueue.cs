using System.Collections.Concurrent;

public static class ServerCommandQueue
{
    private static readonly ConcurrentQueue<DataTransferObj> Queue = new();
    private static long _nextId = 0;

    public static void Enqueue(string type, string path = "", string content = "", string objectType = "")
    {
        var msg = new DataTransferObj
        {
            id = Interlocked.Increment(ref _nextId),
            type = type,
            path = path,
            objectType = objectType,
            content = content
        };
        Queue.Enqueue(msg);
    }

    public static List<DataTransferObj> DequeueMany(int max = 10)
    {
        var list = new List<DataTransferObj>();
        while (list.Count < max && Queue.TryDequeue(out var msg))
        {
            list.Add(msg);
        }
        return list;
    }
}
