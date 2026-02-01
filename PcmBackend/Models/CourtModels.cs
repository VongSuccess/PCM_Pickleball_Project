using System.ComponentModel.DataAnnotations;

namespace PcmBackend.Models
{
    public class CreateCourtModel
    {
        [Required]
        public string Name { get; set; }
        
        public string Description { get; set; }
        
        [Range(0, double.MaxValue)]
        public decimal PricePerHour { get; set; }
    }

    public class UpdateCourtModel : CreateCourtModel
    {
        public bool IsActive { get; set; }
    }
}
