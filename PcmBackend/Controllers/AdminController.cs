using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Data.Entities;
using Microsoft.AspNetCore.SignalR;
using PcmBackend.Hubs;

namespace PcmBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<Members> _userManager;
        private readonly IHubContext<PcmHub> _hubContext;

        public AdminController(ApplicationDbContext context, UserManager<Members> userManager, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _userManager = userManager;
            _hubContext = hubContext;
        }

        // PUT: api/admin/wallet/approve/{transactionId}
        [HttpPut("wallet/approve/{transactionId}")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<IActionResult> ApproveDeposit(int transactionId)
        {
            var transaction = await _context.WalletTransactions
                .Include(t => t.Member)
                .FirstOrDefaultAsync(t => t.Id == transactionId);

            if (transaction == null)
                return NotFound(new { message = "Không tìm thấy giao dịch" });

            if (transaction.Status != TransactionStatus.Pending)
                return BadRequest(new { message = "Giao dịch đã được xử lý" });

            if (transaction.Type != TransactionType.Deposit)
                return BadRequest(new { message = "Chỉ có thể duyệt giao dịch nạp tiền" });

            using var txn = await _context.Database.BeginTransactionAsync();
            try
            {
                // Update transaction status
                transaction.Status = TransactionStatus.Completed;

                // Add to wallet balance
                transaction.Member.WalletBalance += transaction.Amount;

                await _context.SaveChangesAsync();
                await txn.CommitAsync();

                // Send SignalR notification to user
                await _hubContext.Clients.User(transaction.MemberId).SendAsync("ReceiveNotification", new
                {
                    Message = $"Yêu cầu nạp {transaction.Amount:N0}đ của bạn đã được duyệt!",
                    Type = "Success", // or WalletUpdate
                    Timestamp = DateTime.UtcNow
                });

                return Ok(new { 
                    success = true, 
                    message = $"Đã duyệt nạp {transaction.Amount:N0}đ cho {transaction.Member.FullName}",
                    newBalance = transaction.Member.WalletBalance
                });
            }
            catch (Exception ex)
            {
                await txn.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi xử lý: " + ex.Message });
            }
        }

        // PUT: api/admin/wallet/reject/{transactionId}
        [HttpPut("wallet/reject/{transactionId}")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<IActionResult> RejectDeposit(int transactionId, [FromBody] RejectRequest request)
        {
            var transaction = await _context.WalletTransactions.FindAsync(transactionId);

            if (transaction == null)
                return NotFound(new { message = "Không tìm thấy giao dịch" });

            if (transaction.Status != TransactionStatus.Pending)
                return BadRequest(new { message = "Giao dịch đã được xử lý" });

            transaction.Status = TransactionStatus.Rejected;
            transaction.Description = $"{transaction.Description} [Từ chối: {request.Reason}]";

            await _context.SaveChangesAsync();

            await _hubContext.Clients.User(transaction.MemberId).SendAsync("ReceiveNotification", new
            {
                Message = $"Yêu cầu nạp {transaction.Amount:N0}đ đã bị từ chối. Lý do: {request.Reason}",
                Type = "Error",
                Timestamp = DateTime.UtcNow
            });

            return Ok(new { success = true, message = "Đã từ chối yêu cầu nạp tiền" });
        }

        // GET: api/admin/wallet/pending
        [HttpGet("wallet/pending")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<IActionResult> GetPendingDeposits()
        {
            var pending = await _context.WalletTransactions
                .Include(t => t.Member)
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending)
                .OrderByDescending(t => t.CreatedDate)
                .Select(t => new
                {
                    t.Id,
                    MemberName = t.Member.FullName,
                    MemberUsername = t.Member.UserName,
                    t.Amount,
                    t.Description,
                    t.CreatedDate
                })
                .ToListAsync();

            return Ok(pending);
        }

        // GET: api/admin/dashboard
        [HttpGet("dashboard")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<IActionResult> GetDashboard()
        {
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);

            var totalMembers = await _context.Users.CountAsync();
            
            var monthlyDeposits = await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit 
                         && t.Status == TransactionStatus.Completed
                         && t.CreatedDate >= startOfMonth)
                .SumAsync(t => t.Amount);

            var monthlyPayments = await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Payment 
                         && t.CreatedDate >= startOfMonth)
                .SumAsync(t => Math.Abs(t.Amount));

            var monthlyBookings = await _context.Bookings
                .Where(b => b.CreatedDate >= startOfMonth)
                .CountAsync();

            var pendingDeposits = await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending)
                .CountAsync();

            return Ok(new
            {
                totalMembers,
                monthlyDeposits,
                monthlyPayments,
                monthlyBookings,
                pendingDeposits,
                revenue = monthlyDeposits - monthlyPayments
            });
        }
    }

    public class RejectRequest
    {
        public string Reason { get; set; } = "";
    }
}
