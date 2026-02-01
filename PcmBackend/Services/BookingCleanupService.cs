using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Data.Entities;

namespace PcmBackend.Services
{
    public class BookingCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<BookingCleanupService> _logger;

        public BookingCleanupService(IServiceProvider serviceProvider, ILogger<BookingCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Booking Cleanup Service started.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CleanupUnpaidBookingsAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error cleaning up unpaid bookings");
                }

                // Chạy mỗi 1 phút
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }

        private async Task CleanupUnpaidBookingsAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var expiredTime = DateTime.UtcNow.AddMinutes(-5);

            // Tìm các booking "PendingPayment" (Hold) quá 5 phút
            var expiredBookings = await context.Bookings
                .Where(b => b.Status == BookingStatus.PendingPayment && b.CreatedDate < expiredTime)
                .ToListAsync();

            if (expiredBookings.Any())
            {
                foreach (var booking in expiredBookings)
                {
                    booking.Status = BookingStatus.Cancelled;
                    _logger.LogInformation($"Auto-cancelled booking #{booking.Id} due to payment timeout");
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"Cleaned up {expiredBookings.Count} expired bookings");
            }
        }
    }
}
