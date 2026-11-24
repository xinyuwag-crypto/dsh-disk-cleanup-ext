// DSH Disk Cleanup - Chrome native messaging host.
// Speaks the Chrome stdio protocol: 4-byte little-endian length prefix + UTF-8 JSON.
// Kept dependency-free (System.IO / System.Text only) so Add-Type can build it with no package restore.
using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

internal static class Host
{
    private static readonly string ReportsDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".dsh", "disk-cleanup", "reports");

    private static int Main()
    {
        Stream input = Console.OpenStandardInput();
        Stream output = Console.OpenStandardOutput();

        while (true)
        {
            string request = ReadFrame(input);
            if (request == null) break;

            string id = Extract(request, "id");
            string action = Extract(request, "action");
            if (string.IsNullOrEmpty(action)) action = "status";

            string payload;
            bool ok = true;
            try
            {
                payload = Handle(action);
            }
            catch (Exception error)
            {
                ok = false;
                payload = "{\"error\":\"" + Escape(error.Message) + "\"}";
            }

            if (action == "quit") break;

            string response = "{\"id\":\"" + Escape(id) + "\",\"ok\":" + (ok ? "true" : "false") + ",\"data\":" + payload + "}";
            WriteFrame(output, response);
        }

        return 0;
    }

    private static string Handle(string action)
    {
        switch (action)
        {
            case "structure":
                return ReadJson("structure.json");
            case "status":
                return ReadJson("latest.json");
            case "report":
                return "{\"markdown\":\"" + Escape(ReadText("structure.md")) + "\"}";
            case "ping":
                return "{\"host\":\"dsh-disk-cleanup\",\"reports\":\"" + Escape(ReportsDir) + "\"}";
            default:
                return "{\"error\":\"unknown action: " + Escape(action) + "\"}";
        }
    }

    private static string ReadText(string name)
    {
        string path = Path.Combine(ReportsDir, name);
        if (!File.Exists(path)) throw new FileNotFoundException("report not found: " + name);
        return File.ReadAllText(path, Encoding.UTF8);
    }

    private static string ReadJson(string name)
    {
        string text = ReadText(name).Trim();
        if (text.Length == 0) return "{}";
        // Guard against a partially written report so the extension never receives broken JSON.
        if (text[0] != '{' && text[0] != '[') throw new InvalidDataException("not a JSON object: " + name);
        return text;
    }

    private static string Extract(string json, string key)
    {
        Match match = Regex.Match(json, "\"" + Regex.Escape(key) + "\"\\s*:\\s*\"([^\"]*)\"");
        return match.Success ? match.Groups[1].Value : string.Empty;
    }

    private static string Escape(string value)
    {
        if (string.IsNullOrEmpty(value)) return string.Empty;
        return value.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t");
    }

    private static string ReadFrame(Stream input)
    {
        byte[] lengthBytes = new byte[4];
        int read = 0;
        while (read < 4)
        {
            int chunk = input.Read(lengthBytes, read, 4 - read);
            if (chunk <= 0) return null;
            read += chunk;
        }

        int length = BitConverter.ToInt32(lengthBytes, 0);
        if (length <= 0 || length > 64 * 1024 * 1024) return null;

        byte[] buffer = new byte[length];
        read = 0;
        while (read < length)
        {
            int chunk = input.Read(buffer, read, length - read);
            if (chunk <= 0) return null;
            read += chunk;
        }

        return Encoding.UTF8.GetString(buffer);
    }

    private static void WriteFrame(Stream output, string json)
    {
        byte[] body = Encoding.UTF8.GetBytes(json);
        byte[] head = BitConverter.GetBytes(body.Length);
        output.Write(head, 0, 4);
        output.Write(body, 0, body.Length);
        output.Flush();
    }
}
