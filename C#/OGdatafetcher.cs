public static async Task FetchHexNumberInformationAsync()

{
    var hexFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "hex_numbers.txt");
    var apiUrl = "http://api.monni.moe/map?k=";

    try
    {
        using (var httpClient = new HttpClient())
        {
            var hexNumbers = File.ReadAllLines(hexFilePath);
            string fetchedInfoFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "fetched_info.txt");

            foreach (var hexNumber in hexNumbers)
            {
                var url = apiUrl + hexNumber;

                using var response = await httpClient.GetAsync(url, CancellationToken.None);
                response.EnsureSuccessStatusCode();

                var responseBody = await response.Content.ReadAsStringAsync();
                var responseData = JsonSerializer.Deserialize<ResponseData>(responseBody);

                // Find the version with the highest number
                if (responseData != null && responseData.versions != null)
                {
                    var maxVersion = responseData.versions.OrderByDescending(v => v.createdAt).FirstOrDefault();

                    if (maxVersion != null)
                    {
                        var fetchedInfo = new List<string>();

                        // Get the "created at" UNIX time from the newest version
                        var createdAt = maxVersion.createdAt;

                        // Find metadata for the diff
                        var metadata = responseData.metadata;

                        // Check if metadata exists and contains the LevelAuthorName
                        if (metadata != null && metadata.levelAuthorName != null)
                        {
                            fetchedInfo.Add($"LevelAuthorName: {metadata.levelAuthorName},");
                        }

                        if (fetchedInfo.Any())
                        {
                            var fetchedData = $"{hexNumber}: Uploaded: {createdAt}, {string.Join(" ", fetchedInfo)}";

                            // Check if the file exists
                            if (File.Exists(fetchedInfoFilePath))
                            {
                                // Read all existing lines from the file
                                var existingLines = File.ReadAllLines(fetchedInfoFilePath);

                                // Find the index of the line that starts with the current hexNumber
                                var index = Array.FindIndex(existingLines, line => line.StartsWith(hexNumber + ":"));

                                // Create the new line to replace the existing line
                                var newLine = fetchedData;

                                // If the hexNumber line already exists, replace it; otherwise, add the new line at the end
                                if (index != -1)
                                {
                                    existingLines[index] = newLine;
                                }
                                else
                                {
                                    existingLines = existingLines.Append(newLine).ToArray();
                                }
                                // Write all the sorted lines back to the file
                                File.WriteAllLines(fetchedInfoFilePath, existingLines);
                            }
                            else
                            {
                                // Create a new file and write the new line to it
                                File.WriteAllText(fetchedInfoFilePath, fetchedData + Environment.NewLine);
                            }
                        }
                        else
                        {
                            Console.WriteLine($"No valid difficulty information found for hex number: {hexNumber}");
                        }
                    }
                    else
                    {
                        Console.WriteLine($"No diffs found for hex number: {hexNumber}");
                    }
                }
                else
                {
                    Console.WriteLine($"No versions found for hex number: {hexNumber}");
                }
            }
        }

        Console.WriteLine("Fetched information saved successfully.");
        Console.WriteLine("Process completed.");
    }
    catch (HttpRequestException ex)
    {
        Console.WriteLine($"Request failed: {ex.Message}");
    }
    catch (InvalidOperationException ex)
    {
        Console.WriteLine($"Invalid operation: {ex.Message}");
    }
    catch (OperationCanceledException)
    {
        Console.WriteLine("Request cancelled.");
    }
    catch (IOException ex)
    {
        Console.WriteLine($"Error reading/writing file: {ex.Message}");
    }
}

class ResponseData
{
    public List<VersionData>? versions { get; set; }
    public MetadataData? metadata { get; set; }
}

class MetadataData
{
    public string? levelAuthorName { get; set; }
}

class VersionData
{
    public long createdAt { get; set; }
}