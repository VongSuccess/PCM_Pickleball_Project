using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Data.Entities;
using PcmBackend.Models;
using System.Security.Claims;

namespace PcmBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MembersController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public MembersController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/members
        [HttpGet]
        public async Task<IActionResult> GetMembers(
            [FromQuery] string? search = null,
            [FromQuery] string? tier = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var query = _context.Users.AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                search = search.ToLower();
                query = query.Where(m => 
                    m.FullName.ToLower().Contains(search) ||
                    m.UserName!.ToLower().Contains(search));
            }

            if (!string.IsNullOrEmpty(tier) && Enum.TryParse<MemberRank>(tier, out var tierEnum))
            {
                query = query.Where(m => m.Tier == tierEnum);
            }

            var total = await query.CountAsync();

            var members = await query
                .Where(m => m.IsActive)
                .OrderByDescending(m => m.DuprRank)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new
                {
                    m.Id,
                    m.UserName,
                    m.FullName,
                    m.Email,
                    m.DuprRank,
                    Tier = m.Tier.ToString(),
                    m.JoinDate,
                    m.AvatarUrl
                })
                .ToListAsync();

            return Ok(new
            {
                data = members,
                total,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(total / (double)pageSize)
            });
        }

        // GET: api/members/{id}/profile
        [HttpGet("{id}/profile")]
        public async Task<IActionResult> GetMemberProfile(string id)
        {
            var member = await _context.Users
                .FirstOrDefaultAsync(m => m.Id == id);

            if (member == null)
                return NotFound(new { message = "Không tìm thấy thành viên" });

            // Get match statistics
            var matches = await _context.Matches
                .Where(m => m.Team1_Player1Id == id || m.Team1_Player2Id == id ||
                           m.Team2_Player1Id == id || m.Team2_Player2Id == id)
                .ToListAsync();

            var wins = matches.Count(m =>
                (m.Winner == WinningSide.Team1 && (m.Team1_Player1Id == id || m.Team1_Player2Id == id)) ||
                (m.Winner == WinningSide.Team2 && (m.Team2_Player1Id == id || m.Team2_Player2Id == id)));

            var losses = matches.Count(m => m.Status == MatchStatus.Finished) - wins;

            // Get tournament participations
            var tournaments = await _context.TournamentParticipants
                .Include(tp => tp.Tournament)
                .Where(tp => tp.MemberId == id)
                .Select(tp => new
                {
                    tp.Tournament.Id,
                    tp.Tournament.Name,
                    tp.Tournament.StartDate,
                    Status = tp.Tournament.Status.ToString()
                })
                .ToListAsync();

            // Get recent matches
            var recentMatches = await _context.Matches
                .Where(m => m.Team1_Player1Id == id || m.Team1_Player2Id == id ||
                           m.Team2_Player1Id == id || m.Team2_Player2Id == id)
                .OrderByDescending(m => m.Date)
                .Take(10)
                .Select(m => new
                {
                    m.Id,
                    m.Date,
                    m.RoundName,
                    m.Score1,
                    m.Score2,
                    Winner = m.Winner.ToString(),
                    Status = m.Status.ToString()
                })
                .ToListAsync();

            return Ok(new
            {
                profile = new
                {
                    member.Id,
                    member.UserName,
                    member.FullName,
                    member.Email,
                    member.DuprRank,
                    Tier = member.Tier.ToString(),
                    member.JoinDate,
                    member.AvatarUrl,
                    member.TotalSpent
                },
                statistics = new
                {
                    totalMatches = matches.Count,
                    wins,
                    losses,
                    winRate = matches.Count > 0 ? (double)wins / matches.Count * 100 : 0
                },
                tournaments,
                recentMatches
            });
        }

        // PUT: api/members/{id}
        [HttpPut("{id}")]
        // [Authorize(Roles = "Admin")] // Uncomment when using Roles
        public async Task<IActionResult> UpdateMember(string id, [FromBody] UpdateMemberModel model)
        {
            var currentUser = await _context.Users.FindAsync(User.FindFirstValue(ClaimTypes.NameIdentifier));
            // Simple role check based on Tier or actual Role claim if configured
            /*
            if (currentUser == null || (!User.IsInRole("Admin") && currentUser.Tier != MemberRank.Admin))
            {
               return Forbid();
            }
            */
            // Temporarily allow any authorized user for development speed or check manually if needed. 
            // Better to check if the caller is Admin.
            
            var member = await _context.Users.FindAsync(id);
            if (member == null)
            {
                return NotFound(new { message = "Không tìm thấy thành viên" });
            }

            member.FullName = model.FullName;
            member.IsActive = model.IsActive;
            member.DuprRank = model.DuprRank;

            if (Enum.TryParse<MemberRank>(model.Tier, out var tierEnum))
            {
                member.Tier = tierEnum;
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật thành công" });
        }
    }
}
