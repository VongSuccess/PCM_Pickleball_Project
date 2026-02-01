
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Data.Entities
{
    public class TournamentParticipants
    {
        public int Id { get; set; }
        public int TournamentId { get; set; }
        [ForeignKey("TournamentId")]
        public Tournaments Tournament { get; set; }

        public string MemberId { get; set; }
        [ForeignKey("MemberId")]
        public Members Member { get; set; }

        public string? TeamName { get; set; }
        public bool PaymentStatus { get; set; }
        public DateTime RegisteredDate { get; set; } = DateTime.UtcNow;
    }
}
