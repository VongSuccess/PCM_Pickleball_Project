using Microsoft.AspNetCore.SignalR;

namespace PcmBackend.Hubs
{
    public class PcmHub : Hub
    {
        // Gửi thông báo tới một user cụ thể
        public async Task SendNotification(string userId, string message, string type)
        {
            await Clients.User(userId).SendAsync("ReceiveNotification", new
            {
                Message = message,
                Type = type,
                Timestamp = DateTime.UtcNow
            });
        }

        // Thông báo cập nhật lịch sân (broadcast cho tất cả)
        public async Task UpdateCalendar(int courtId, DateTime startTime, DateTime endTime, string status)
        {
            await Clients.All.SendAsync("UpdateCalendar", new
            {
                CourtId = courtId,
                StartTime = startTime,
                EndTime = endTime,
                Status = status
            });
        }

        // Thông báo cập nhật tỉ số trận đấu (chỉ gửi cho group đang xem trận đó)
        public async Task UpdateMatchScore(int matchId, int score1, int score2, string details)
        {
            await Clients.Group($"match_{matchId}").SendAsync("UpdateMatchScore", new
            {
                MatchId = matchId,
                Score1 = score1,
                Score2 = score2,
                Details = details
            });
        }

        // User join vào group xem trận đấu
        public async Task JoinMatchGroup(int matchId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"match_{matchId}");
        }

        // User rời khỏi group
        public async Task LeaveMatchGroup(int matchId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"match_{matchId}");
        }

        public override async Task OnConnectedAsync()
        {
            Console.WriteLine($"Client connected: {Context.ConnectionId}");
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            Console.WriteLine($"Client disconnected: {Context.ConnectionId}");
            await base.OnDisconnectedAsync(exception);
        }
    }
}
