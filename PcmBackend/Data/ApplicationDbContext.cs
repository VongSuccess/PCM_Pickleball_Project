
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data.Entities;

namespace PcmBackend.Data
{
    public class ApplicationDbContext : IdentityDbContext<Members>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // Prefix 761 for tables - MSSV: 1771020761 (Nguyễn Vọng)
        public DbSet<Members> Members { get; set; }
        public DbSet<WalletTransactions> WalletTransactions { get; set; }
        // ... more dbsets to come

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Rename tables with prefix 761
            builder.Entity<Members>().ToTable("761_Members");
            builder.Entity<WalletTransactions>().ToTable("761_WalletTransactions");
            
            // Rename Identity Tables
            builder.Entity<IdentityRole>().ToTable("761_Roles");
            builder.Entity<IdentityUserRole<string>>().ToTable("761_UserRoles");
            builder.Entity<IdentityUserClaim<string>>().ToTable("761_UserClaims");
            builder.Entity<IdentityUserLogin<string>>().ToTable("761_UserLogins");
            builder.Entity<IdentityRoleClaim<string>>().ToTable("761_RoleClaims");
            builder.Entity<IdentityUserToken<string>>().ToTable("761_UserTokens");

            // Rename Domain Tables
            builder.Entity<Courts>().ToTable("761_Courts");
            builder.Entity<Bookings>().ToTable("761_Bookings");
            builder.Entity<Tournaments>().ToTable("761_Tournaments");
            builder.Entity<TournamentParticipants>().ToTable("761_TournamentParticipants");
            builder.Entity<Matches>().ToTable("761_Matches");
            builder.Entity<Notifications>().ToTable("761_Notifications");
            builder.Entity<News>().ToTable("761_News");

            // Configurations
            builder.Entity<WalletTransactions>()
                .Property(w => w.Amount)
                .HasColumnType("decimal(18,2)");
                
            builder.Entity<Members>()
                .Property(m => m.WalletBalance)
                .HasColumnType("decimal(18,2)");
                
            builder.Entity<Members>()
                .Property(m => m.TotalSpent)
                .HasColumnType("decimal(18,2)");

            builder.Entity<Courts>()
                .Property(c => c.PricePerHour)
                .HasColumnType("decimal(18,2)");

            builder.Entity<Bookings>()
                .Property(b => b.TotalPrice)
                .HasColumnType("decimal(18,2)");

            builder.Entity<Tournaments>()
                .Property(t => t.EntryFee)
                .HasColumnType("decimal(18,2)");

            builder.Entity<Tournaments>()
                .Property(t => t.PrizePool)
                .HasColumnType("decimal(18,2)");
        }

        // DbSets
        public DbSet<Courts> Courts { get; set; }
        public DbSet<Bookings> Bookings { get; set; }
        public DbSet<Tournaments> Tournaments { get; set; }
        public DbSet<TournamentParticipants> TournamentParticipants { get; set; }
        public DbSet<Matches> Matches { get; set; }
        public DbSet<Notifications> Notifications { get; set; }
        public DbSet<News> News { get; set; }
    }
}
