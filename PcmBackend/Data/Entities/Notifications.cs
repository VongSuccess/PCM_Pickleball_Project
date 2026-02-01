
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Data.Entities
{
    public enum NotificationType
    {
        Info,
        Success,
        Warning,
        Error
    }

    public class Notifications
    {
        public int Id { get; set; }
        public string ReceiverId { get; set; }
        [ForeignKey("ReceiverId")]
        public Members Receiver { get; set; }

        public string Message { get; set; }
        public NotificationType Type { get; set; }
        public string? LinkUrl { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    }
}
