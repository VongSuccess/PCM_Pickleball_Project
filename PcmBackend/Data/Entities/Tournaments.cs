
namespace PcmBackend.Data.Entities
{
    public enum TournamentFormat
    {
        RoundRobin, // Vòng tròn
        Knockout,   // Loại trực tiếp
        Hybrid      // Kết hợp
    }

    public enum TournamentStatus
    {
        Open,           // Mở đăng ký
        Registering,    // Đang đăng ký
        DrawCompleted,  // Đã bốc thăm
        Ongoing,        // Đang diễn ra
        Finished        // Kết thúc
    }

    public class Tournaments
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public TournamentFormat Format { get; set; }
        public decimal EntryFee { get; set; }
        public decimal PrizePool { get; set; }
        public TournamentStatus Status { get; set; }
        public string? Settings { get; set; } // JSON
    }
}
