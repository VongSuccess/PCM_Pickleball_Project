using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using PcmBackend.Data.Entities;
using PcmBackend.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<Members> _userManager;
        private readonly SignInManager<Members> _signInManager;
        private readonly IConfiguration _configuration;

        public AuthController(
            UserManager<Members> userManager,
            SignInManager<Members> signInManager,
            IConfiguration configuration)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _configuration = configuration;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = new Members
            {
                UserName = model.Username,
                Email = model.Email,
                FullName = model.FullName,
                JoinDate = DateTime.UtcNow,
                IsActive = true,
                WalletBalance = 0,
                Tier = MemberRank.Standard,
                TotalSpent = 0
            };

            var result = await _userManager.CreateAsync(user, model.Password);

            if (result.Succeeded)
            {
                return Ok(new AuthResponseModel
                {
                    Success = true,
                    Message = "Đăng ký thành công!",
                    Token = await GenerateJwtToken(user),
                    User = MapToUserInfo(user, new List<string> { "Member" }) // Default role
                });
            }

            return BadRequest(new AuthResponseModel
            {
                Success = false,
                Message = string.Join(", ", result.Errors.Select(e => e.Description))
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginModel model)
        {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
            {
                return Unauthorized(new AuthResponseModel
                {
                    Success = false,
                    Message = "Tài khoản không tồn tại!"
                });
            }

            var result = await _signInManager.CheckPasswordSignInAsync(user, model.Password, false);

            if (result.Succeeded)
            {
                return Ok(new AuthResponseModel
                {
                    Success = true,
                    Message = "Đăng nhập thành công!",
                    Token = await GenerateJwtToken(user),
                    User = MapToUserInfo(user, await _userManager.GetRolesAsync(user))
                });
            }

            return Unauthorized(new AuthResponseModel
            {
                Success = false,
                Message = "Sai mật khẩu!"
            });
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return NotFound();

            var roles = await _userManager.GetRolesAsync(user);

            return Ok(new AuthResponseModel
            {
                Success = true,
                User = MapToUserInfo(user, roles)
            });
        }

        private async Task<string> GenerateJwtToken(Members user)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["SecretKey"]!));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            // Get user roles from Identity
            var roles = await _userManager.GetRolesAsync(user);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.UserName!),
                new Claim(ClaimTypes.Email, user.Email!),
                new Claim("FullName", user.FullName ?? "")
            };

            // Add role claims
            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var token = new JwtSecurityToken(
                issuer: jwtSettings["Issuer"],
                audience: jwtSettings["Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddDays(7),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private UserInfoModel MapToUserInfo(Members user, IList<string> roles)
        {
            return new UserInfoModel
            {
                Id = user.Id,
                Username = user.UserName!,
                Email = user.Email!,
                FullName = user.FullName,
                WalletBalance = user.WalletBalance,
                Tier = user.Tier.ToString(),
                AvatarUrl = user.AvatarUrl,
                Role = roles.FirstOrDefault() ?? "Member"
            };
        }
    }
}
