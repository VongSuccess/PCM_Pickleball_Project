using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Data.Entities;
using PcmBackend.Models;
using System.Security.Claims;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TournamentsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public TournamentsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetTournaments([FromQuery] string? status = null)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var query = _context.Tournaments.AsQueryable();

            if (!string.IsNullOrEmpty(status) && Enum.TryParse<TournamentStatus>(status, out var statusEnum))
            {
                query = query.Where(t => t.Status == statusEnum);
            }

            var tournaments = await query
                .Select(t => new TournamentResponseModel
                {
                    Id = t.Id,
                    Name = t.Name,
                    StartDate = t.StartDate,
                    EndDate = t.EndDate,
                    Format = t.Format.ToString(),
                    EntryFee = t.EntryFee,
                    PrizePool = t.PrizePool,
                    Status = t.Status.ToString(),
                    ParticipantCount = _context.TournamentParticipants.Count(p => p.TournamentId == t.Id),
                    IsJoined = userId != null && _context.TournamentParticipants.Any(p => p.TournamentId == t.Id && p.MemberId == userId)
                })
                .ToListAsync();

            return Ok(tournaments);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetTournament(int id)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null)
                return NotFound();

            var participants = await _context.TournamentParticipants
                .Include(p => p.Member)
                .Where(p => p.TournamentId == id)
                .Select(p => new
                {
                    p.Id,
                    p.MemberId, // Added for frontend mapping
                    p.TeamName,
                    MemberName = p.Member.FullName,
                    p.PaymentStatus,
                    p.RegisteredDate
                })
                .ToListAsync();

            var matches = await _context.Matches
                .Where(m => m.TournamentId == id)
                .Select(m => new MatchResponseModel
                {
                    Id = m.Id,
                    RoundName = m.RoundName,
                    Date = m.Date,
                    StartTime = m.StartTime,
                    Team1Player1 = m.Team1_Player1Id,
                    Team1Player2 = m.Team1_Player2Id,
                    Team2Player1 = m.Team2_Player1Id,
                    Team2Player2 = m.Team2_Player2Id,
                    Score1 = m.Score1,
                    Score2 = m.Score2,
                    Details = m.Details,
                    Winner = m.Winner.ToString(),
                    Status = m.Status.ToString()
                })
                .ToListAsync();

            return Ok(new
            {
                Tournament = new TournamentResponseModel
                {
                    Id = tournament.Id,
                    Name = tournament.Name,
                    StartDate = tournament.StartDate,
                    EndDate = tournament.EndDate,
                    Format = tournament.Format.ToString(),
                    EntryFee = tournament.EntryFee,
                    PrizePool = tournament.PrizePool,
                    Status = tournament.Status.ToString(),
                    ParticipantCount = participants.Count
                },
                Participants = participants,
                Matches = matches
            });
        }

        [HttpPost("{id}/join")]
        [Authorize]
        public async Task<IActionResult> JoinTournament(int id, [FromBody] JoinTournamentModel model)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FindAsync(userId);
            var tournament = await _context.Tournaments.FindAsync(id);

            if (member == null || tournament == null)
                return BadRequest("Dữ liệu không hợp lệ");

            if (tournament.Status != TournamentStatus.Open && tournament.Status != TournamentStatus.Registering)
                return BadRequest("Giải đấu không còn mở đăng ký");

            // Check if already joined
            var alreadyJoined = await _context.TournamentParticipants
                .AnyAsync(p => p.TournamentId == id && p.MemberId == userId);

            if (alreadyJoined)
                return BadRequest("Bạn đã đăng ký giải này rồi");

            // Check wallet
            if (member.WalletBalance < tournament.EntryFee)
                return BadRequest($"Số dư không đủ. Cần {tournament.EntryFee:N0}đ");

            // Deduct entry fee
            member.WalletBalance -= tournament.EntryFee;
            member.TotalSpent += tournament.EntryFee;

            // Create participant
            var participant = new TournamentParticipants
            {
                TournamentId = id,
                MemberId = userId!,
                TeamName = model.TeamName,
                PaymentStatus = true,
                RegisteredDate = DateTime.UtcNow
            };

            // Create transaction
            var transaction = new WalletTransactions
            {
                MemberId = userId!,
                Amount = -tournament.EntryFee,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                RelatedId = id.ToString(),
                Description = $"Phí tham gia giải {tournament.Name}",
                CreatedDate = DateTime.UtcNow
            };

            _context.TournamentParticipants.Add(participant);
            _context.WalletTransactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new { Success = true, Message = "Đăng ký giải đấu thành công!" });
        }

        // POST: api/tournaments - Admin tạo giải đấu mới
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateTournament([FromBody] CreateTournamentModel model)
        {
            if (!Enum.TryParse<TournamentFormat>(model.Format, out var format))
                return BadRequest("Format không hợp lệ");

            var tournament = new Tournaments
            {
                Name = model.Name,
                StartDate = model.StartDate,
                EndDate = model.EndDate,
                Format = format,
                EntryFee = model.EntryFee,
                PrizePool = model.PrizePool,
                Status = TournamentStatus.Open
            };

            _context.Tournaments.Add(tournament);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Success = true,
                Message = "Tạo giải đấu thành công!",
                Tournament = new TournamentResponseModel
                {
                    Id = tournament.Id,
                    Name = tournament.Name,
                    StartDate = tournament.StartDate,
                    EndDate = tournament.EndDate,
                    Format = tournament.Format.ToString(),
                    EntryFee = tournament.EntryFee,
                    PrizePool = tournament.PrizePool,
                    Status = tournament.Status.ToString(),
                    ParticipantCount = 0
                }
            });
        }

        // POST: api/tournaments/{id}/generate-schedule - Auto generate matches
        [HttpPost("{id}/generate-schedule")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GenerateSchedule(int id)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null)
                return NotFound("Không tìm thấy giải đấu");

            var participants = await _context.TournamentParticipants
                .Include(p => p.Member)
                .Where(p => p.TournamentId == id)
                .OrderBy(p => Guid.NewGuid()) // Random shuffle
                .ToListAsync();

            if (participants.Count < 2)
                return BadRequest("Cần ít nhất 2 người tham gia để tạo lịch");

            // Clear existing matches
            var existingMatches = await _context.Matches.Where(m => m.TournamentId == id).ToListAsync();
            _context.Matches.RemoveRange(existingMatches);

            var matches = new List<Matches>();
            var matchDate = tournament.StartDate;

            if (tournament.Format == TournamentFormat.Knockout)
            {
                // Single Elimination Bracket
                var roundNum = 1;
                var matchesInRound = participants.Count / 2;
                List<string?> seeds = participants.Select(p => (string?)p.MemberId).ToList();

                while (matchesInRound >= 1)
                {
                    var roundName = matchesInRound == 1 ? "Chung kết" :
                                    matchesInRound == 2 ? "Bán kết" :
                                    $"Vòng {roundNum}";

                    for (int i = 0; i < matchesInRound && i * 2 + 1 < seeds.Count; i++)
                    {
                        var match = new Matches
                        {
                            TournamentId = id,
                            RoundName = roundName,
                            Date = matchDate,
                            Team1_Player1Id = seeds.Count > i * 2 ? seeds[i * 2] : null,
                            Team2_Player1Id = seeds.Count > i * 2 + 1 ? seeds[i * 2 + 1] : null,
                            Status = MatchStatus.Scheduled,
                            Winner = WinningSide.None
                        };
                        matches.Add(match);
                    }

                    matchDate = matchDate.AddDays(1);
                    roundNum++;
                    matchesInRound /= 2;
                    seeds = new List<string?>(); // Cleared for next round (filled by match results)
                }
            }
            else if (tournament.Format == TournamentFormat.RoundRobin || tournament.Format == TournamentFormat.Hybrid)
            {
                // Simple Round Robin OR Group Stage for Hybrid
                // For Hybrid: We treat it as Group Stage (Round Robin within Groups)
                
                var groups = 1;
                if (tournament.Format == TournamentFormat.Hybrid && !string.IsNullOrEmpty(tournament.Settings))
                {
                    try
                    {
                        // Simple parsing to avoid extra dependencies if not already imported
                        // Assuming Settings is like {"groups": 4 ...}
                        var json = System.Text.Json.JsonDocument.Parse(tournament.Settings);
                        if (json.RootElement.TryGetProperty("groups", out var groupElement))
                        {
                            groups = groupElement.GetInt32();
                        }
                    }
                    catch { groups = 4; } // Default to 4 if parse fails
                }

                var random = new Random();
                var totalDays = (tournament.EndDate - tournament.StartDate).Days;
                if (totalDays < 1) totalDays = 1;

                // Divide participants into groups
                var groupLists = new List<List<TournamentParticipants>>();
                for (int i = 0; i < groups; i++) groupLists.Add(new List<TournamentParticipants>());

                for (int i = 0; i < participants.Count; i++)
                {
                    groupLists[i % groups].Add(participants[i]);
                }

                // Generate matches for each group
                for (int g = 0; g < groups; g++)
                {
                    var groupParticipants = groupLists[g];
                    var groupName = groups > 1 ? $"Bảng {(char)('A' + g)}" : "Vòng bảng";

                    for (int i = 0; i < groupParticipants.Count; i++)
                    {
                        for (int j = i + 1; j < groupParticipants.Count; j++)
                        {
                            var randomDay = random.Next(0, totalDays + 1);
                            var randomMatchDate = tournament.StartDate.AddDays(randomDay);
                            
                            var randomHour = random.Next(8, 20);
                            var randomMinute = random.Next(0, 4) * 15;
                            var startTime = new TimeSpan(randomHour, randomMinute, 0);

                            var match = new Matches
                            {
                                TournamentId = id,
                                RoundName = groupName,
                                Date = randomMatchDate,
                                StartTime = startTime,
                                Team1_Player1Id = groupParticipants[i].MemberId,
                                Team2_Player1Id = groupParticipants[j].MemberId,
                                Status = MatchStatus.Scheduled,
                                Winner = WinningSide.None
                            };
                            matches.Add(match);
                        }
                    }
                }
            }

            tournament.Status = TournamentStatus.Ongoing;
            _context.Matches.AddRange(matches);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Success = true,
                Message = $"Đã tạo {matches.Count} trận đấu cho giải {tournament.Name}",
                MatchesCreated = matches.Count
            });
        }
        // POST: api/tournaments/{id}/finish - End tournament and award prize
        [HttpPost("{id}/finish")]
        // [Authorize(Roles = "Admin")]
        public async Task<IActionResult> FinishTournament(int id)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound("Không tìm thấy giải đấu");

            if (tournament.Status == TournamentStatus.Finished)
                return BadRequest("Giải đấu đã kết thúc");

            // Check if final match exists and is finished
            var matches = await _context.Matches
                .Where(m => m.TournamentId == id)
                .ToListAsync();

            if (matches.Count == 0)
                 return BadRequest("Giải đấu chưa có trận đấu nào");

            // Logic to find winner depends on Format.
            // For Knockout: The winner of the very last match (by Date/Time or Round Name "Chung kết")
            var finalMatch = matches
                .OrderByDescending(m => m.RoundName == "Chung kết") // Prioritize Final
                .ThenByDescending(m => m.Date)
                .ThenByDescending(m => m.StartTime)
                .FirstOrDefault();

            if (finalMatch == null || finalMatch.Status != MatchStatus.Finished)
                return BadRequest("Trận chung kết chưa kết thúc hoặc chưa diễn ra");

            string? winnerId = null;
            if (finalMatch.Winner == WinningSide.Team1)
            {
                // In single player team
                winnerId = finalMatch.Team1_Player1Id; 
                // Note: For doubles, we might need to award both. Simplified to Player1 for now or split prize.
            }
            else if (finalMatch.Winner == WinningSide.Team2)
            {
                winnerId = finalMatch.Team2_Player1Id;
            }
            else
            {
                 return BadRequest("Trận chung kết chưa có người thắng");
            }

            if (winnerId == null) return BadRequest("Không xác định được người thắng");

            // Award Prize
            if (tournament.PrizePool > 0)
            {
                var winner = await _context.Members.FindAsync(winnerId);
                if (winner != null)
                {
                    winner.WalletBalance += tournament.PrizePool;
                    
                    var transaction = new WalletTransactions
                    {
                        MemberId = winner.Id,
                        Amount = tournament.PrizePool,
                        Type = TransactionType.Refund, // Or custom type "Prize"
                        Status = TransactionStatus.Completed,
                        RelatedId = id.ToString(),
                        Description = $"Thưởng vô địch giải {tournament.Name}",
                        CreatedDate = DateTime.UtcNow
                    };
                    
                    _context.WalletTransactions.Add(transaction);
                }
            }

            tournament.Status = TournamentStatus.Finished;
            await _context.SaveChangesAsync();

            return Ok(new { Success = true, Message = "Đã kết thúc giải đấu và trao thưởng!" });
        }
    }
}
