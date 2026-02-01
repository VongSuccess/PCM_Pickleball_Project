using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Data.Entities;
using Microsoft.AspNetCore.SignalR;
using PcmBackend.Hubs;
using System.Security.Claims;

namespace PcmBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MatchesController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public MatchesController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        // GET: api/matches
        [HttpGet]
        public async Task<IActionResult> GetMatches(
            [FromQuery] int? tournamentId = null,
            [FromQuery] string? status = null)
        {
            var query = _context.Matches.AsQueryable();

            if (tournamentId.HasValue)
                query = query.Where(m => m.TournamentId == tournamentId);

            if (!string.IsNullOrEmpty(status) && Enum.TryParse<MatchStatus>(status, out var statusEnum))
                query = query.Where(m => m.Status == statusEnum);

            var matches = await query
                .OrderByDescending(m => m.Date)
                .ThenBy(m => m.StartTime)
                .Take(100)
                .Select(m => new
                {
                    m.Id,
                    m.TournamentId,
                    m.RoundName,
                    m.Date,
                    m.StartTime,
                    m.Team1_Player1Id,
                    m.Team1_Player2Id,
                    m.Team2_Player1Id,
                    m.Team2_Player2Id,
                    m.Score1,
                    m.Score2,
                    m.Details,
                    Winner = m.Winner.ToString(),
                    m.IsRanked,
                    Status = m.Status.ToString()
                })
                .ToListAsync();

            return Ok(matches);
        }

        // GET: api/matches/my
        [HttpGet("my")]
        [Authorize]
        public async Task<IActionResult> GetMyMatches()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var matches = await _context.Matches
                .Include(m => m.Tournament) // Include Tournament info if needed
                .Where(m => m.Team1_Player1Id == userId || m.Team1_Player2Id == userId ||
                            m.Team2_Player1Id == userId || m.Team2_Player2Id == userId)
                .OrderByDescending(m => m.Date)
                .ThenByDescending(m => m.StartTime)
                .Select(m => new
                {
                    m.Id,
                    m.TournamentId,
                    TournamentName = m.Tournament == null ? "Giao hữu" : m.Tournament.Name,
                    m.RoundName,
                    m.Date,
                    m.StartTime,
                    m.Score1,
                    m.Score2,
                    Winner = m.Winner.ToString(),
                    Status = m.Status.ToString(),
                    m.IsRanked
                })
                .ToListAsync();

            return Ok(matches);
        }

        // GET: api/matches/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetMatch(int id)
        {
            var match = await _context.Matches
                .Include(m => m.Tournament)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (match == null)
                return NotFound();

            // Get player names
            var playerIds = new[] { 
                match.Team1_Player1Id, match.Team1_Player2Id, 
                match.Team2_Player1Id, match.Team2_Player2Id 
            }.Where(id => id != null).ToList();

            var players = await _context.Users
                .Where(u => playerIds.Contains(u.Id))
                .ToDictionaryAsync(u => u.Id, u => u.FullName);

            return Ok(new
            {
                match.Id,
                match.TournamentId,
                TournamentName = match.Tournament?.Name,
                match.RoundName,
                match.Date,
                match.StartTime,
                Team1 = new
                {
                    Player1 = match.Team1_Player1Id != null ? players.GetValueOrDefault(match.Team1_Player1Id) : null,
                    Player2 = match.Team1_Player2Id != null ? players.GetValueOrDefault(match.Team1_Player2Id) : null
                },
                Team2 = new
                {
                    Player1 = match.Team2_Player1Id != null ? players.GetValueOrDefault(match.Team2_Player1Id) : null,
                    Player2 = match.Team2_Player2Id != null ? players.GetValueOrDefault(match.Team2_Player2Id) : null
                },
                match.Score1,
                match.Score2,
                match.Details,
                Winner = match.Winner.ToString(),
                match.IsRanked,
                Status = match.Status.ToString()
            });
        }

        // POST: api/matches/{id}/result
        [HttpPost("{id}/result")]
        [Authorize(Roles = "Admin,Referee")]
        public async Task<IActionResult> UpdateResult(int id, [FromBody] UpdateMatchResultRequest request)
        {
            var match = await _context.Matches.FindAsync(id);
            if (match == null)
                return NotFound();

            if (match.Status == MatchStatus.Finished)
                return BadRequest(new { message = "Trận đấu đã kết thúc" });

            match.Score1 = request.Score1;
            match.Score2 = request.Score2;
            match.Details = request.Details;
            match.Winner = request.Score1 > request.Score2 ? WinningSide.Team1 : WinningSide.Team2;
            match.Status = MatchStatus.Finished;

            // Update DUPR if ranked match
            if (match.IsRanked)
            {
                await UpdateDuprRanks(match);
            }

            await _context.SaveChangesAsync();

            // TODO: Notify via SignalR
            // TODO: Update next round if Knockout tournament

            return Ok(new { 
                success = true, 
                message = "Cập nhật kết quả thành công",
                winner = match.Winner.ToString()
            });
        }

        // POST: api/matches/duel
        [HttpPost("duel")]
        [Authorize]
        public async Task<IActionResult> CreateDuel([FromBody] CreateDuelRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            
            // Validate opponent
            if (string.IsNullOrEmpty(request.OpponentId) || request.OpponentId == userId)
                return BadRequest(new { message = "Đối thủ không hợp lệ" });

            if (!_context.Users.Any(u => u.Id == request.OpponentId))
                return BadRequest(new { message = "Không tìm thấy đối thủ" });

            var match = new Matches
            {
                TournamentId = null, // Duel
                RoundName = "Thách đấu",
                Date = DateTime.UtcNow.Date,
                StartTime = DateTime.UtcNow.TimeOfDay,
                Team1_Player1Id = userId,
                Team2_Player1Id = request.OpponentId,
                Status = MatchStatus.Scheduled,
                IsRanked = true // Duels affect rank
            };

            _context.Matches.Add(match);
            await _context.SaveChangesAsync();

            // Notify Opponent
            await _hubContext.Clients.User(request.OpponentId).SendAsync("ReceiveNotification", new
            {
                Message = $"Bạn nhận được lời thách đấu từ một người chơi!", // Could resolve challenger name
                Type = "Info",
                Timestamp = DateTime.UtcNow
            });

            return Ok(new { success = true, message = "Đã gửi lời thách đấu!", matchId = match.Id });
        }


        private async Task UpdateDuprRanks(Matches match)
        {
            var winnerIds = new List<string>();
            var loserIds = new List<string>();

            if (match.Winner == WinningSide.Team1)
            {
                if (match.Team1_Player1Id != null) winnerIds.Add(match.Team1_Player1Id);
                if (match.Team1_Player2Id != null) winnerIds.Add(match.Team1_Player2Id);
                if (match.Team2_Player1Id != null) loserIds.Add(match.Team2_Player1Id);
                if (match.Team2_Player2Id != null) loserIds.Add(match.Team2_Player2Id);
            }
            else
            {
                if (match.Team2_Player1Id != null) winnerIds.Add(match.Team2_Player1Id);
                if (match.Team2_Player2Id != null) winnerIds.Add(match.Team2_Player2Id);
                if (match.Team1_Player1Id != null) loserIds.Add(match.Team1_Player1Id);
                if (match.Team1_Player2Id != null) loserIds.Add(match.Team1_Player2Id);
            }

            // Simple DUPR adjustment: +0.1 for win, -0.05 for loss
            var winners = await _context.Users.Where(u => winnerIds.Contains(u.Id)).ToListAsync();
            foreach (var w in winners)
            {
                w.DuprRank = Math.Min(8.0, (w.DuprRank ?? 3.0) + 0.1);
            }

            var losers = await _context.Users.Where(u => loserIds.Contains(u.Id)).ToListAsync();
            foreach (var l in losers)
            {
                l.DuprRank = Math.Max(2.0, (l.DuprRank ?? 3.0) - 0.05);
            }
        }
    }

    public class UpdateMatchResultRequest
    {
        public int Score1 { get; set; }
        public int Score2 { get; set; }
        public string? Details { get; set; }
    }

    public class CreateDuelRequest
    {
        public string OpponentId { get; set; } = string.Empty;
    }
}
