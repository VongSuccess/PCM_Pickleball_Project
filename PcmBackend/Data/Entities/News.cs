using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Data.Entities
{
    public class News
    {
        public int Id { get; set; }
        
        [Required]
        public string Title { get; set; } = "";
        
        public string? Content { get; set; }
        
        public bool IsPinned { get; set; }
        
        public string? ImageUrl { get; set; }
        
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        
        public string? CreatedById { get; set; }
        
        [ForeignKey("CreatedById")]
        public Members? CreatedBy { get; set; }
    }
}
