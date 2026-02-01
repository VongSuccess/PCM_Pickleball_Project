
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Data.Entities
{
    public enum TransactionType
    {
        Deposit,
        Withdraw,
        Payment,
        Refund,
        Reward
    }

    public enum TransactionStatus
    {
        Pending,
        Completed,
        Rejected,
        Failed
    }

    public class WalletTransactions
    {
        public int Id { get; set; }
        public string MemberId { get; set; }
        [ForeignKey("MemberId")]
        public Members Member { get; set; }

        public decimal Amount { get; set; }
        public TransactionType Type { get; set; }
        public TransactionStatus Status { get; set; }
        public string? RelatedId { get; set; } // BookingId or TournamentId
        public string? Description { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    }
}
