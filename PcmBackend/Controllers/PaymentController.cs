using Microsoft.AspNetCore.Mvc;
using PcmBackend.Models;
using PcmBackend.Services;

namespace PcmBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IVnPayService _vnPayService;

        public PaymentController(IVnPayService vnPayService)
        {
            _vnPayService = vnPayService;
        }

        [HttpPost("vnpay/create-url")]
        public IActionResult CreatePaymentUrl([FromBody] PaymentInformationModel model)
        {
            try
            {
                var url = _vnPayService.CreatePaymentUrl(HttpContext, model);
                Console.WriteLine("VNPay URL: " + url); // Debug LOG
                return Ok(new { url });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("vnpay/return")]
        public IActionResult PaymentReturn()
        {
            var response = _vnPayService.PaymentExecute(Request.Query);
            // This is usually called by the browser redirect. 
            // In Mobile App context, the App WebView intercepts the URL before it hits this (or after).
            // But if we want to confirm on backend strictly:
            return Ok(response);
        }

        [HttpGet("vnpay/ipn")]
        public IActionResult PaymentIpn()
        {
            // IPN is called by VNPay server to notify payment status silently
            var response = _vnPayService.PaymentExecute(Request.Query);
            
            if (response.Success)
            {
                // TODO: Update Database (Add money to wallet)
                // Need to inject WalletService or DbContext here to update balance
                // For now, just log or return success code
                return Ok(new { RspCode = "00", Message = "Confirm Success" });
            }
            
            return Ok(new { RspCode = "02", Message = "Order already confirmed" }); // Example code
        }
    }
}
