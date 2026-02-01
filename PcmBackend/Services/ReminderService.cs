using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Data.Entities;
using PcmBackend.Hubs;

namespace PcmBackend.Services
{
    /// <summary>
    /// Background Service gửi thông báo nhắc lịch đấu/đặt sân trước 1 ngày
    /// Chạy mỗi 30 phút để kiểm tra và gửi reminder
    /// </summary>
    public class ReminderService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<ReminderService> _logger;

        public ReminderService(IServiceProvider serviceProvider, ILogger<ReminderService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Reminder Service started.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await SendBookingRemindersAsync();
                    await SendMatchRemindersAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in Reminder Service");
                }

                // Chạy mỗi 30 phút
                await Task.Delay(TimeSpan.FromMinutes(30), stoppingToken);
            }
        }

        /// <summary>
        /// Gửi thông báo nhắc booking trước 23-24h
        /// </summary>
        private async Task SendBookingRemindersAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<PcmHub>>();

            var now = DateTime.UtcNow;
            var reminderStart = now.AddHours(23);
            var reminderEnd = now.AddHours(24);

            // Tìm bookings có StartTime trong khoảng 23-24h tiếp theo và chưa được nhắc
            var upcomingBookings = await context.Bookings
                .Include(b => b.Court)
                .Include(b => b.Member)
                .Where(b => b.Status == BookingStatus.Confirmed)
                .Where(b => b.StartTime >= reminderStart && b.StartTime <= reminderEnd)
                .ToListAsync();

            foreach (var booking in upcomingBookings)
            {
                // Kiểm tra xem đã gửi notification chưa (tránh gửi trùng)
                var alreadyNotified = await context.Notifications
                    .AnyAsync(n => n.ReceiverId == booking.MemberId 
                                && n.LinkUrl == $"/bookings/{booking.Id}"
                                && n.CreatedDate >= now.AddHours(-24));

                if (alreadyNotified) continue;

                // Tạo notification trong DB
                var notification = new Notifications
                {
                    ReceiverId = booking.MemberId,
                    Message = $"⏰ Nhắc nhở: Bạn có lịch đặt sân {booking.Court.Name} vào lúc {booking.StartTime.ToLocalTime():HH:mm} ngày mai ({booking.StartTime.ToLocalTime():dd/MM})",
                    Type = NotificationType.Info,
                    LinkUrl = $"/bookings/{booking.Id}",
                    IsRead = false,
                    CreatedDate = DateTime.UtcNow
                };

                context.Notifications.Add(notification);

                // Gửi SignalR real-time
                await hubContext.Clients.User(booking.MemberId).SendAsync("ReceiveNotification", new
                {
                    Message = notification.Message,
                    Type = "Reminder",
                    Timestamp = DateTime.UtcNow,
                    LinkUrl = notification.LinkUrl
                });

                _logger.LogInformation($"Sent booking reminder to {booking.Member.FullName} for {booking.Court.Name}");
            }

            if (upcomingBookings.Any())
            {
                await context.SaveChangesAsync();
                _logger.LogInformation($"Sent {upcomingBookings.Count} booking reminders");
            }
        }

        /// <summary>
        /// Gửi thông báo nhắc match/giải đấu trước 23-24h
        /// </summary>
        private async Task SendMatchRemindersAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<PcmHub>>();

            var now = DateTime.UtcNow;
            var reminderStart = now.AddHours(23);
            var reminderEnd = now.AddHours(24);

            // Tìm matches có Date trong khoảng 23-24h tiếp theo
            var upcomingMatches = await context.Matches
                .Include(m => m.Tournament)
                .Where(m => m.Status == MatchStatus.Scheduled)
                .Where(m => m.Date >= reminderStart.Date && m.Date <= reminderEnd.Date)
                .ToListAsync();

            foreach (var match in upcomingMatches)
            {
                // Lấy tất cả player IDs của trận đấu
                var playerIds = new List<string?>
                {
                    match.Team1_Player1Id,
                    match.Team1_Player2Id,
                    match.Team2_Player1Id,
                    match.Team2_Player2Id
                }.Where(id => !string.IsNullOrEmpty(id)).Distinct().ToList();

                foreach (var playerId in playerIds)
                {
                    if (string.IsNullOrEmpty(playerId)) continue;

                    // Kiểm tra đã gửi chưa
                    var alreadyNotified = await context.Notifications
                        .AnyAsync(n => n.ReceiverId == playerId
                                    && n.LinkUrl == $"/matches/{match.Id}"
                                    && n.CreatedDate >= now.AddHours(-24));

                    if (alreadyNotified) continue;

                    var tournamentName = match.Tournament?.Name ?? "Trận giao hữu";
                    var roundInfo = !string.IsNullOrEmpty(match.RoundName) ? $" - {match.RoundName}" : "";

                    // Tạo notification
                    var notification = new Notifications
                    {
                        ReceiverId = playerId,
                        Message = $"🏸 Nhắc nhở: Bạn có trận đấu {tournamentName}{roundInfo} vào ngày mai ({match.Date.ToLocalTime():dd/MM}) lúc {match.StartTime:hh\\:mm}",
                        Type = NotificationType.Info,
                        LinkUrl = $"/matches/{match.Id}",
                        IsRead = false,
                        CreatedDate = DateTime.UtcNow
                    };

                    context.Notifications.Add(notification);

                    // Gửi SignalR
                    await hubContext.Clients.User(playerId).SendAsync("ReceiveNotification", new
                    {
                        Message = notification.Message,
                        Type = "Reminder",
                        Timestamp = DateTime.UtcNow,
                        LinkUrl = notification.LinkUrl
                    });

                    _logger.LogInformation($"Sent match reminder to player {playerId} for match {match.Id}");
                }
            }

            await context.SaveChangesAsync();
        }
    }
}
