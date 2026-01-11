namespace DigiMem.Services;

public interface IGeminiService
{
    Task<string> GenerateSummaryImageAsync(string userId, DateTime startDate, DateTime endDate, string periodType);
}
