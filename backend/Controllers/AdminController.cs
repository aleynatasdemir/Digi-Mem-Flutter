using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DigiMem.Data;
using DigiMem.Models;
using System.Security.Claims;

namespace DigiMem.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;

    public AdminController(AppDbContext context, UserManager<ApplicationUser> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    // GET: api/admin/users
    [HttpGet("users")]
    public async Task<ActionResult<object>> GetUsers(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] bool? isBanned = null)
    {
        Console.WriteLine($"[AdminController] GetUsers called by user: {User.Identity?.Name}");
        Console.WriteLine($"[AdminController] User is in Admin role: {User.IsInRole("Admin")}");
        
        var query = _userManager.Users.AsQueryable();

        // Search filter
        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(u => 
                u.Email!.Contains(search) || 
                (u.UserName != null && u.UserName.Contains(search)));
        }

        // Ban status filter
        if (isBanned.HasValue)
        {
            query = query.Where(u => u.IsBanned == isBanned.Value);
        }

        var total = await query.CountAsync();
        var users = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                u.Id,
                u.Email,
                u.UserName,
                u.ProfilePhotoUrl,
                u.IsBanned,
                u.CreatedAt,
                u.EmailConfirmed,
                u.PhoneNumber
            })
            .ToListAsync();

        return Ok(new
        {
            users,
            total,
            page,
            pageSize,
            totalPages = (int)Math.Ceiling((double)total / pageSize)
        });
    }

    // GET: api/admin/users/{userId}
    [HttpGet("users/{userId}")]
    public async Task<ActionResult<object>> GetUserDetails(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            return NotFound();
        }

        // Get user's memory statistics
        var memories = await _context.Memories.Where(m => m.UserId == userId).ToListAsync();
        var totalMemories = memories.Count;
        var memoriesByType = memories.GroupBy(m => m.Type)
            .Select(g => new { type = g.Key, count = g.Count() })
            .ToList();

        // Calculate date ranges
        var now = DateTime.UtcNow;
        var startOfToday = now.Date;
        var startOfWeek = now.AddDays(-(int)now.DayOfWeek);
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var todayMemories = memories.Count(m => m.CreatedAt >= startOfToday);
        var weekMemories = memories.Count(m => m.CreatedAt >= startOfWeek);
        var monthMemories = memories.Count(m => m.CreatedAt >= startOfMonth);

        // Last 30 days activity
        var last30Days = new List<object>();
        for (int i = 29; i >= 0; i--)
        {
            var date = now.AddDays(-i).Date;
            var count = memories.Count(m => m.CreatedAt.Date == date);
            last30Days.Add(new
            {
                date = date.ToString("yyyy-MM-dd"),
                count
            });
        }

        return Ok(new
        {
            user = new
            {
                user.Id,
                user.Email,
                user.UserName,
                user.ProfilePhotoUrl,
                user.IsBanned,
                user.CreatedAt,
                user.EmailConfirmed,
                user.PhoneNumber
            },
            statistics = new
            {
                totalMemories,
                todayMemories,
                weekMemories,
                monthMemories,
                memoriesByType,
                last30Days
            }
        });
    }

    // POST: api/admin/users/{userId}/ban
    [HttpPost("users/{userId}/ban")]
    public async Task<ActionResult> BanUser(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            return NotFound();
        }

        // Don't allow banning admins
        var isAdmin = await _userManager.IsInRoleAsync(user, "Admin");
        if (isAdmin)
        {
            return BadRequest(new { message = "Admin kullanıcıları banlanamaz." });
        }

        user.IsBanned = true;
        await _userManager.UpdateAsync(user);

        return Ok(new { message = "Kullanıcı banlandı.", user = new { user.Id, user.Email, user.IsBanned } });
    }

    // POST: api/admin/users/{userId}/unban
    [HttpPost("users/{userId}/unban")]
    public async Task<ActionResult> UnbanUser(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            return NotFound();
        }

        user.IsBanned = false;
        await _userManager.UpdateAsync(user);

        return Ok(new { message = "Kullanıcının banı kaldırıldı.", user = new { user.Id, user.Email, user.IsBanned } });
    }

    // GET: api/admin/stats
    [HttpGet("stats")]
    public async Task<ActionResult<object>> GetGlobalStats()
    {
        var totalUsers = await _userManager.Users.CountAsync();
        var bannedUsers = await _userManager.Users.CountAsync(u => u.IsBanned);
        var totalMemories = await _context.Memories.CountAsync();

        var now = DateTime.UtcNow;
        var startOfToday = now.Date;
        var startOfWeek = now.AddDays(-(int)now.DayOfWeek);
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var newUsersToday = await _userManager.Users.CountAsync(u => u.CreatedAt >= startOfToday);
        var newUsersWeek = await _userManager.Users.CountAsync(u => u.CreatedAt >= startOfWeek);
        var newUsersMonth = await _userManager.Users.CountAsync(u => u.CreatedAt >= startOfMonth);

        var memoriesToday = await _context.Memories.CountAsync(m => m.CreatedAt >= startOfToday);
        var memoriesWeek = await _context.Memories.CountAsync(m => m.CreatedAt >= startOfWeek);
        var memoriesMonth = await _context.Memories.CountAsync(m => m.CreatedAt >= startOfMonth);

        return Ok(new
        {
            users = new
            {
                total = totalUsers,
                banned = bannedUsers,
                active = totalUsers - bannedUsers,
                newToday = newUsersToday,
                newWeek = newUsersWeek,
                newMonth = newUsersMonth
            },
            memories = new
            {
                total = totalMemories,
                today = memoriesToday,
                week = memoriesWeek,
                month = memoriesMonth
            }
        });
    }
}
