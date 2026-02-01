namespace PcmBackend.Models
{
    public class LoginModel
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }

    public class RegisterModel
    {
        public string Username { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public string FullName { get; set; }
    }

    public class AuthResponseModel
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string Token { get; set; }
        public UserInfoModel User { get; set; }
    }

    public class UserInfoModel
    {
        public string Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public string FullName { get; set; }
        public decimal WalletBalance { get; set; }
        public string Tier { get; set; }
        public string AvatarUrl { get; set; }
        public string Role { get; set; }
    }
}
