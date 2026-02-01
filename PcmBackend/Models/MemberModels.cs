using System.ComponentModel.DataAnnotations;

namespace PcmBackend.Models
{
    public class UpdateMemberModel
    {
        [Required]
        public string FullName { get; set; }
        
        public string Tier { get; set; }
        
        public double? DuprRank { get; set; }
        
        public bool IsActive { get; set; }
    }
}
