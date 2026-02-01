
namespace PcmBackend.Data.Entities
{
    public class Courts
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public bool IsActive { get; set; }
        public string? Description { get; set; }
        public decimal PricePerHour { get; set; }
    }
}
