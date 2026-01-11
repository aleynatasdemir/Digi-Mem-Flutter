using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;

namespace DigiMem.Data;

public static class Seed
{
    public static async Task EnsureAdmin(IServiceProvider sp)
    {
        var userMgr = sp.GetRequiredService<UserManager<ApplicationUser>>();
        var roleMgr = sp.GetRequiredService<RoleManager<IdentityRole>>();

        // Ensure Admin role exists
        if (!await roleMgr.RoleExistsAsync("Admin"))
        {
            await roleMgr.CreateAsync(new IdentityRole("Admin"));
        }

        // Create default admin user (admin@local)
        var email = Environment.GetEnvironmentVariable("ADMIN_EMAIL") ?? "admin@local";
        var pass  = Environment.GetEnvironmentVariable("ADMIN_PASSWORD") ?? "Admin!12345";

        var user = await userMgr.FindByEmailAsync(email);
        if (user == null)
        {
            user = new ApplicationUser { UserName = email, Email = email, EmailConfirmed = true };
            await userMgr.CreateAsync(user, pass);
            await userMgr.AddToRoleAsync(user, "Admin");
        }

        // Create aleyna@admin super admin
        var superAdminEmail = "aleyna@admin";
        var superAdminPass = "aley12345";
        var superAdmin = await userMgr.FindByEmailAsync(superAdminEmail);
        if (superAdmin == null)
        {
            superAdmin = new ApplicationUser 
            { 
                UserName = superAdminEmail, 
                Email = superAdminEmail, 
                EmailConfirmed = true 
            };
            await userMgr.CreateAsync(superAdmin, superAdminPass);
            await userMgr.AddToRoleAsync(superAdmin, "Admin");
        }

        var testUsers = new[]
        {
            ("user@local", "123456"),
            ("test@local", "Test123!"),
            ("demo@user.com", "Demo123!")
        };

        foreach (var (userEmail, userPassword) in testUsers)
        {
            var testUser = await userMgr.FindByEmailAsync(userEmail);
            if (testUser == null)
            {
                testUser = new ApplicationUser
                {
                    UserName = userEmail,
                    Email = userEmail,
                    EmailConfirmed = true
                };
                await userMgr.CreateAsync(testUser, userPassword);
                // Regular users don't get Admin role
            }
        }
    }
}
