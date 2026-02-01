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
    [Authorize]
    public class BookingsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public BookingsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet("calendar")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCalendar([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            var bookings = await _context.Bookings
                .Include(b => b.Court)
                .Where(b => b.StartTime >= from && b.EndTime <= to)
                .Where(b => b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.PendingPayment)
                .Select(b => new BookingResponseModel
                {
                    Id = b.Id,
                    CourtName = b.Court.Name,
                    MemberId = b.MemberId,
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    TotalPrice = b.TotalPrice,
                    Status = b.Status.ToString()
                })
                .ToListAsync();

            return Ok(bookings);
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMyBookings()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var bookings = await _context.Bookings
                .Include(b => b.Court)
                .Where(b => b.MemberId == userId)
                .OrderByDescending(b => b.StartTime)
                .Select(b => new BookingResponseModel
                {
                    Id = b.Id,
                    CourtName = b.Court.Name,
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    TotalPrice = b.TotalPrice,
                    Status = b.Status.ToString()
                })
                .ToListAsync();

            return Ok(bookings);
        }

        [HttpPost]
        public async Task<IActionResult> CreateBooking([FromBody] BookingRequestModel model)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FindAsync(userId);
            var court = await _context.Courts.FindAsync(model.CourtId);

            if (member == null || court == null)
                return BadRequest("Dữ liệu không hợp lệ");

            // Check for conflicts
            var hasConflict = await _context.Bookings.AnyAsync(b =>
                b.CourtId == model.CourtId &&
                b.Status != BookingStatus.Cancelled &&
                ((b.StartTime <= model.StartTime && b.EndTime > model.StartTime) ||
                 (b.StartTime < model.EndTime && b.EndTime >= model.EndTime) ||
                 (b.StartTime >= model.StartTime && b.EndTime <= model.EndTime)));

            if (hasConflict)
                return BadRequest("Khung giờ này đã có người đặt!");

            // Calculate price
            var hours = (decimal)(model.EndTime - model.StartTime).TotalHours;
            var totalPrice = hours * court.PricePerHour;

            // Check wallet balance
            if (member.WalletBalance < totalPrice)
                return BadRequest($"Số dư không đủ. Cần {totalPrice:N0}đ, hiện có {member.WalletBalance:N0}đ");

            // Create booking
            var booking = new Bookings
            {
                CourtId = model.CourtId,
                MemberId = userId!,
                StartTime = model.StartTime,
                EndTime = model.EndTime,
                TotalPrice = totalPrice,
                Status = BookingStatus.Confirmed,
                CreatedDate = DateTime.UtcNow
            };

            // Deduct wallet
            member.WalletBalance -= totalPrice;
            member.TotalSpent += totalPrice;

            // Create transaction
            var transaction = new WalletTransactions
            {
                MemberId = userId!,
                Amount = -totalPrice,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Đặt sân {court.Name} ({model.StartTime:dd/MM HH:mm} - {model.EndTime:HH:mm})",
                CreatedDate = DateTime.UtcNow
            };

            _context.Bookings.Add(booking);
            _context.WalletTransactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Success = true,
                Message = "Đặt sân thành công!",
                Booking = new BookingResponseModel
                {
                    Id = booking.Id,
                    CourtName = court.Name,
                    StartTime = booking.StartTime,
                    EndTime = booking.EndTime,
                    TotalPrice = booking.TotalPrice,
                    Status = booking.Status.ToString()
                }
            });
        }

        [HttpPost("cancel/{id}")]
        public async Task<IActionResult> CancelBooking(int id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var booking = await _context.Bookings
                .Include(b => b.Court)
                .FirstOrDefaultAsync(b => b.Id == id && b.MemberId == userId);

            if (booking == null)
                return NotFound("Không tìm thấy booking");

            if (booking.Status == BookingStatus.Cancelled)
                return BadRequest("Booking đã bị hủy trước đó");

            // Refund policy: 100% if > 24h before
            var hoursUntilStart = (booking.StartTime - DateTime.UtcNow).TotalHours;
            var refundRate = hoursUntilStart > 24 ? 1.0m : hoursUntilStart > 6 ? 0.5m : 0m;
            var refundAmount = booking.TotalPrice * refundRate;

            booking.Status = BookingStatus.Cancelled;

            var member = await _context.Members.FindAsync(userId);
            if (member != null && refundAmount > 0)
            {
                member.WalletBalance += refundAmount;

                var refundTransaction = new WalletTransactions
                {
                    MemberId = userId!,
                    Amount = refundAmount,
                    Type = TransactionType.Refund,
                    Status = TransactionStatus.Completed,
                    Description = $"Hoàn tiền hủy sân {booking.Court.Name} ({refundRate * 100}%)",
                    CreatedDate = DateTime.UtcNow
                };
                _context.WalletTransactions.Add(refundTransaction);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Success = true,
                Message = $"Đã hủy booking. Hoàn tiền: {refundAmount:N0}đ ({refundRate * 100}%)"
            });
        }

        // POST: api/bookings/recurring - Đặt sân định kỳ (VIP Only)
        [HttpPost("recurring")]
        public async Task<IActionResult> CreateRecurringBooking([FromBody] RecurringBookingRequestModel model)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FindAsync(userId);
            var court = await _context.Courts.FindAsync(model.CourtId);

            if (member == null || court == null)
                return BadRequest("Dữ liệu không hợp lệ");

            // Check VIP tier
            if (member.Tier != MemberRank.Gold && member.Tier != MemberRank.Diamond)
                return BadRequest("Chỉ thành viên Gold/Diamond được đặt sân định kỳ");

            // Parse recurrence rule (e.g., "MON,WED,FRI" or "2,4,6" for days of week)
            var daysOfWeek = ParseRecurrenceRule(model.RecurrenceRule);
            if (!daysOfWeek.Any())
                return BadRequest("Quy tắc lặp không hợp lệ");

            // Generate booking dates
            var bookingDates = new List<DateTime>();
            var currentDate = model.StartDate;
            while (currentDate <= model.EndDate && bookingDates.Count < 20) // Max 20 bookings
            {
                if (daysOfWeek.Contains(currentDate.DayOfWeek))
                {
                    bookingDates.Add(currentDate);
                }
                currentDate = currentDate.AddDays(1);
            }

            if (!bookingDates.Any())
                return BadRequest("Không có ngày nào phù hợp trong khoảng thời gian đã chọn");

            // Calculate total price
            var hours = (decimal)(model.EndTime - model.StartTime).TotalHours;
            var pricePerBooking = hours * court.PricePerHour;
            var totalPrice = pricePerBooking * bookingDates.Count;

            // Check wallet balance
            if (member.WalletBalance < totalPrice)
                return BadRequest($"Số dư không đủ. Cần {totalPrice:N0}đ cho {bookingDates.Count} buổi");

            // Check for conflicts
            var createdBookings = new List<Bookings>();
            var conflictDates = new List<string>();

            foreach (var date in bookingDates)
            {
                var startDateTime = date.Date + model.StartTime;
                var endDateTime = date.Date + model.EndTime;

                var hasConflict = await _context.Bookings.AnyAsync(b =>
                    b.CourtId == model.CourtId &&
                    b.Status != BookingStatus.Cancelled &&
                    b.StartTime < endDateTime && b.EndTime > startDateTime);

                if (hasConflict)
                {
                    conflictDates.Add(date.ToString("dd/MM/yyyy"));
                    continue;
                }

                var booking = new Bookings
                {
                    CourtId = model.CourtId,
                    MemberId = userId!,
                    StartTime = startDateTime,
                    EndTime = endDateTime,
                    TotalPrice = pricePerBooking,
                    IsRecurring = true,
                    RecurrenceRule = model.RecurrenceRule,
                    Status = BookingStatus.Confirmed,
                    CreatedDate = DateTime.UtcNow
                };
                createdBookings.Add(booking);
            }

            if (!createdBookings.Any())
                return BadRequest($"Tất cả các ngày đã bị trùng lịch: {string.Join(", ", conflictDates)}");

            // Calculate actual total
            var actualTotal = pricePerBooking * createdBookings.Count;
            member.WalletBalance -= actualTotal;
            member.TotalSpent += actualTotal;

            // Create transaction
            var transaction = new WalletTransactions
            {
                MemberId = userId!,
                Amount = -actualTotal,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Đặt sân định kỳ {court.Name} ({createdBookings.Count} buổi)",
                CreatedDate = DateTime.UtcNow
            };

            _context.Bookings.AddRange(createdBookings);
            _context.WalletTransactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Success = true,
                Message = $"Đặt sân định kỳ thành công! {createdBookings.Count} buổi",
                BookingsCreated = createdBookings.Count,
                ConflictDates = conflictDates,
                TotalPrice = actualTotal
            });
        }

        private static List<DayOfWeek> ParseRecurrenceRule(string rule)
        {
            var days = new List<DayOfWeek>();
            if (string.IsNullOrEmpty(rule)) return days;

            var parts = rule.ToUpper().Split(',', ';', ' ');
            foreach (var part in parts)
            {
                switch (part.Trim())
                {
                    case "MON": case "T2": case "1": days.Add(DayOfWeek.Monday); break;
                    case "TUE": case "T3": case "2": days.Add(DayOfWeek.Tuesday); break;
                    case "WED": case "T4": case "3": days.Add(DayOfWeek.Wednesday); break;
                    case "THU": case "T5": case "4": days.Add(DayOfWeek.Thursday); break;
                    case "FRI": case "T6": case "5": days.Add(DayOfWeek.Friday); break;
                    case "SAT": case "T7": case "6": days.Add(DayOfWeek.Saturday); break;
                    case "SUN": case "CN": case "0": case "7": days.Add(DayOfWeek.Sunday); break;
                }
            }
            return days;
        }
    }
}
