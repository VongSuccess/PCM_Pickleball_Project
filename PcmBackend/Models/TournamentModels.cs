namespace PcmBackend.Models
{
    public class TournamentResponseModel
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Format { get; set; }
        public decimal EntryFee { get; set; }
        public decimal PrizePool { get; set; }
        public string Status { get; set; }
        public int ParticipantCount { get; set; }
        public bool IsJoined { get; set; }
    }

    public class JoinTournamentModel
    {
        public string TeamName { get; set; }
    }

    public class MatchResponseModel
    {
        public int Id { get; set; }
        public string RoundName { get; set; }
        public DateTime Date { get; set; }
        public TimeSpan StartTime { get; set; }
        public string Team1Player1 { get; set; }
        public string Team1Player2 { get; set; }
        public string Team2Player1 { get; set; }
        public string Team2Player2 { get; set; }
        public int Score1 { get; set; }
        public int Score2 { get; set; }
        public string Details { get; set; }
        public string Winner { get; set; }
        public string Status { get; set; }
    }

    public class UpdateMatchResultModel
    {
        public int Score1 { get; set; }
        public int Score2 { get; set; }
        public string Details { get; set; } = string.Empty; // "11-9, 5-11, 11-8"
    }

    public class CreateTournamentModel
    {
        public string Name { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Format { get; set; } = "SingleElimination"; // SingleElimination, RoundRobin, DoubleElimination
        public decimal EntryFee { get; set; }
        public decimal PrizePool { get; set; }
    }
}
