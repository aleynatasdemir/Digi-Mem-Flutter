namespace DigiMem.Services;

public interface ICollageService
{
    Task<string> GenerateWeeklyCollageAsync(string userId, DateTime weekStart);
    Task<string> GenerateMonthlyCollageAsync(string userId, int year, int month);
    Task<string> GenerateYearlyCollageAsync(string userId, int year);
    Task<List<WeekInfo>> GetAvailableWeeksAsync(string userId, int year, int month);
}

public record WeekInfo(DateTime WeekStart, DateTime WeekEnd, int PhotoCount);
