
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Data.Entities
{
    public enum WinningSide
    {
        None,
        Team1,
        Team2,
        Draw
    }

    public enum MatchStatus
    {
        Scheduled,
        InProgress,
        Finished
    }

    public class Matches
    {
        public int Id { get; set; }
        public int? TournamentId { get; set; }
        [ForeignKey("TournamentId")]
        public Tournaments? Tournament { get; set; }

        public string? RoundName { get; set; }
        public DateTime Date { get; set; }
        public TimeSpan StartTime { get; set; }

        // Players
        public string? Team1_Player1Id { get; set; }
        public string? Team1_Player2Id { get; set; }
        public string? Team2_Player1Id { get; set; }
        public string? Team2_Player2Id { get; set; }

        public int Score1 { get; set; }
        public int Score2 { get; set; }
        public string? Details { get; set; } // Set scores: "11-9, 5-11"
        public WinningSide Winner { get; set; }
        public bool IsRanked { get; set; }
        public MatchStatus Status { get; set; }
    }
}
