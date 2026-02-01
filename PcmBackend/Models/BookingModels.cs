namespace PcmBackend.Models
{
    public class BookingRequestModel
    {
        public int CourtId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
    }

    public class RecurringBookingRequestModel
    {
        public int CourtId { get; set; }
        public string RecurrenceRule { get; set; } = string.Empty; // VD: "MON,WED,FRI"
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
    }

    public class BookingResponseModel
    {
        public int Id { get; set; }
        public string CourtName { get; set; }
        public string MemberId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        public string Status { get; set; }
    }

    public class CourtResponseModel
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public decimal PricePerHour { get; set; }
        public bool IsActive { get; set; }
    }
}
