
using Microsoft.AspNetCore.Identity;

namespace PcmBackend.Data.Entities
{
    public enum MemberRank
    {
        Standard,
        Silver,
        Gold,
        Diamond
    }

    public class Members : IdentityUser
    {
        public string FullName { get; set; }
        public DateTime JoinDate { get; set; }
        public double? DuprRank { get; set; }
        public bool IsActive { get; set; }
        public decimal WalletBalance { get; set; }
        public MemberRank Tier { get; set; }
        public decimal TotalSpent { get; set; }
        public string? AvatarUrl { get; set; }
    }
}
