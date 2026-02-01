
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Data.Entities
{
    public enum BookingStatus
    {
        PendingPayment,
        Confirmed,
        Cancelled,
        Completed
    }

    public class Bookings
    {
        public int Id { get; set; }
        public int CourtId { get; set; }
        [ForeignKey("CourtId")]
        public Courts Court { get; set; }

        public string MemberId { get; set; }
        [ForeignKey("MemberId")]
        public Members Member { get; set; }

        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        
        public int? TransactionId { get; set; }
        [ForeignKey("TransactionId")]
        public WalletTransactions? Transaction { get; set; }

        // Recurring
        public bool IsRecurring { get; set; }
        public string? RecurrenceRule { get; set; }
        public int? ParentBookingId { get; set; }

        public BookingStatus Status { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    }
}
