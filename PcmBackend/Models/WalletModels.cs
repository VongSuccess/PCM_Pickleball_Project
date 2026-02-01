namespace PcmBackend.Models
{
    public class DepositRequestModel
    {
        public decimal Amount { get; set; }
        public string? Description { get; set; }
        public string? ProofImageUrl { get; set; } // Ảnh chứng minh chuyển khoản (optional)
    }

    public class TransactionResponseModel
    {
        public int Id { get; set; }
        public decimal Amount { get; set; }
        public string Type { get; set; }
        public string Status { get; set; }
        public string Description { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    public class WalletInfoModel
    {
        public decimal Balance { get; set; }
        public List<TransactionResponseModel> RecentTransactions { get; set; }
    }
}
