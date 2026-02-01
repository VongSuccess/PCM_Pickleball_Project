using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data.Entities;

namespace PcmBackend.Data
{
    public static class DbSeeder
    {
        public static async Task SeedAsync(IServiceProvider serviceProvider)
        {
            var context = serviceProvider.GetRequiredService<ApplicationDbContext>();
            var userManager = serviceProvider.GetRequiredService<UserManager<Members>>();
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();

            // Seed Roles
            string[] roles = { "Admin", "Treasurer", "Referee", "Member" };
            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    await roleManager.CreateAsync(new IdentityRole(role));
                }
            }

            // Seed Admin
            if (await userManager.FindByNameAsync("admin") == null)
            {
                var admin = new Members
                {
                    UserName = "admin",
                    Email = "admin@pcm.vn",
                    FullName = "Quản Trị Viên",
                    JoinDate = DateTime.UtcNow.AddYears(-2),
                    IsActive = true,
                    WalletBalance = 50000000,
                    Tier = MemberRank.Diamond,
                    DuprRank = 5.0
                };
                await userManager.CreateAsync(admin, "Admin@123");
                await userManager.AddToRoleAsync(admin, "Admin");
            }

            // Seed Treasurer
            if (await userManager.FindByNameAsync("treasurer") == null)
            {
                var treasurer = new Members
                {
                    UserName = "treasurer",
                    Email = "treasurer@pcm.vn",
                    FullName = "Thủ Quỹ CLB",
                    JoinDate = DateTime.UtcNow.AddYears(-1),
                    IsActive = true,
                    WalletBalance = 100000000,
                    Tier = MemberRank.Gold,
                    DuprRank = 4.5
                };
                await userManager.CreateAsync(treasurer, "Treasurer@123");
                await userManager.AddToRoleAsync(treasurer, "Treasurer");
            }

            // Seed Referee
            if (await userManager.FindByNameAsync("referee") == null)
            {
                var referee = new Members
                {
                    UserName = "referee",
                    Email = "referee@pcm.vn",
                    FullName = "Trọng Tài Chính",
                    JoinDate = DateTime.UtcNow.AddMonths(-6),
                    IsActive = true,
                    WalletBalance = 5000000,
                    Tier = MemberRank.Silver,
                    DuprRank = 4.0
                };
                await userManager.CreateAsync(referee, "Referee@123");
                await userManager.AddToRoleAsync(referee, "Referee");
            }

            // Seed 20 Members
            var random = new Random(42);
            var firstNames = new[] { "Minh", "Hùng", "Tuấn", "Dũng", "Hải", "Long", "Phong", "Bình", "Quang", "Thắng",
                                     "Lan", "Hoa", "Mai", "Linh", "Xuân", "Thu", "Hạnh", "Ngọc", "Yến", "Trang" };
            var lastNames = new[] { "Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng" };
            var tiers = new[] { MemberRank.Standard, MemberRank.Silver, MemberRank.Gold, MemberRank.Diamond };

            for (int i = 1; i <= 20; i++)
            {
                var username = $"member{i:D2}";
                if (await userManager.FindByNameAsync(username) == null)
                {
                    var firstName = firstNames[random.Next(firstNames.Length)];
                    var lastName = lastNames[random.Next(lastNames.Length)];
                    var tier = tiers[random.Next(tiers.Length)];
                    var walletBalance = random.Next(2000000, 10000001); // 2M - 10M
                    var duprRank = Math.Round(2.5 + random.NextDouble() * 2.5, 2); // 2.5 - 5.0

                    var member = new Members
                    {
                        UserName = username,
                        Email = $"{username}@pcm.vn",
                        FullName = $"{lastName} {firstName}",
                        JoinDate = DateTime.UtcNow.AddDays(-random.Next(30, 365)),
                        IsActive = true,
                        WalletBalance = walletBalance,
                        Tier = tier,
                        TotalSpent = random.Next(500000, 5000000),
                        DuprRank = duprRank
                    };
                    await userManager.CreateAsync(member, "Member@123");
                    await userManager.AddToRoleAsync(member, "Member");
                }
            }

            // Seed Courts
            if (!await context.Courts.AnyAsync())
            {
                var courts = new List<Courts>
                {
                    new Courts { Name = "Sân 1 - Indoor", IsActive = true, PricePerHour = 150000, Description = "Sân trong nhà, có điều hòa" },
                    new Courts { Name = "Sân 2 - Indoor", IsActive = true, PricePerHour = 150000, Description = "Sân trong nhà, có điều hòa" },
                    new Courts { Name = "Sân 3 - Outdoor", IsActive = true, PricePerHour = 100000, Description = "Sân ngoài trời, có mái che" },
                    new Courts { Name = "Sân 4 - Outdoor", IsActive = true, PricePerHour = 100000, Description = "Sân ngoài trời, có mái che" },
                    new Courts { Name = "Sân VIP", IsActive = true, PricePerHour = 300000, Description = "Sân tiêu chuẩn thi đấu quốc tế" }
                };
                context.Courts.AddRange(courts);
                await context.SaveChangesAsync();
            }

            // Seed Tournaments
            if (!await context.Tournaments.AnyAsync())
            {
                var tournaments = new List<Tournaments>
                {
                    new Tournaments
                    {
                        Name = "Summer Open 2026",
                        StartDate = DateTime.UtcNow.AddMonths(-2),
                        EndDate = DateTime.UtcNow.AddMonths(-1),
                        Format = TournamentFormat.Knockout,
                        EntryFee = 500000,
                        PrizePool = 10000000,
                        Status = TournamentStatus.Finished,
                        Settings = "{\"maxTeams\": 16, \"seed\": true}"
                    },
                    new Tournaments
                    {
                        Name = "Winter Cup 2026",
                        StartDate = DateTime.UtcNow.AddDays(14),
                        EndDate = DateTime.UtcNow.AddDays(21),
                        Format = TournamentFormat.Hybrid,
                        EntryFee = 300000,
                        PrizePool = 5000000,
                        Status = TournamentStatus.Open,
                        Settings = "{\"maxTeams\": 32, \"groups\": 4}"
                    }
                };
                context.Tournaments.AddRange(tournaments);
                await context.SaveChangesAsync();
            }

            // Seed Tournament Participants for Winter Cup 2026
            var winterCup = await context.Tournaments.FirstOrDefaultAsync(t => t.Name == "Winter Cup 2026");
            if (winterCup != null)
            {
                var members = await userManager.GetUsersInRoleAsync("Member");
                var existingParticipants = await context.TournamentParticipants
                    .Where(p => p.TournamentId == winterCup.Id)
                    .Select(p => p.MemberId)
                    .ToListAsync();

                var newParticipants = new List<TournamentParticipants>();

                foreach (var member in members)
                {
                    if (!existingParticipants.Contains(member.Id))
                    {
                        newParticipants.Add(new TournamentParticipants
                        {
                            TournamentId = winterCup.Id,
                            MemberId = member.Id,
                            TeamName = $"Team {member.FullName}",
                            PaymentStatus = true,
                            RegisteredDate = DateTime.UtcNow
                        });
                    }
                }

                if (newParticipants.Any())
                {
                    context.TournamentParticipants.AddRange(newParticipants);
                    await context.SaveChangesAsync();
                }
            }

            Console.WriteLine("✅ Data seeding completed!");
        }
    }
}
