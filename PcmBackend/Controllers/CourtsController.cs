using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Data.Entities;
using PcmBackend.Models;
using System.Security.Claims;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CourtsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public CourtsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetCourts([FromQuery] bool includeInactive = false)
        {
            var query = _context.Courts.AsQueryable();
            
            if (!includeInactive)
            {
                query = query.Where(c => c.IsActive);
            }

            var courts = await query
                .Select(c => new CourtResponseModel
                {
                    Id = c.Id,
                    Name = c.Name,
                    Description = c.Description,
                    PricePerHour = c.PricePerHour,
                    IsActive = c.IsActive
                })
                .ToListAsync();

            return Ok(courts);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetCourt(int id)
        {
            var court = await _context.Courts.FindAsync(id);
            if (court == null)
                return NotFound();

            return Ok(new CourtResponseModel
            {
                Id = court.Id,
                Name = court.Name,
                Description = court.Description,
                PricePerHour = court.PricePerHour,
                IsActive = court.IsActive
            });
        }

        [HttpPost]
        // [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateCourt([FromBody] CreateCourtModel model)
        {
            var court = new Courts
            {
                Name = model.Name,
                Description = model.Description,
                PricePerHour = model.PricePerHour,
                IsActive = true
            };

            _context.Courts.Add(court);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetCourt), new { id = court.Id }, new CourtResponseModel
            {
                Id = court.Id,
                Name = court.Name,
                Description = court.Description,
                PricePerHour = court.PricePerHour,
                IsActive = court.IsActive
            });
        }

        [HttpPut("{id}")]
        // [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateCourt(int id, [FromBody] UpdateCourtModel model)
        {
            var court = await _context.Courts.FindAsync(id);
            if (court == null)
                return NotFound();

            court.Name = model.Name;
            court.Description = model.Description;
            court.PricePerHour = model.PricePerHour;
            court.IsActive = model.IsActive;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật sân thành công" });
        }

        [HttpDelete("{id}")]
        // [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteCourt(int id)
        {
            var court = await _context.Courts.FindAsync(id);
            if (court == null)
                return NotFound();

            // Soft delete by setting IsActive to false preferably, but renaming Delete implies deletion.
            // Requirement was "Add/Edit/Delete".
            // Implementation: Soft Delete
            court.IsActive = false; 
            
            // If hard delete is required:
            // _context.Courts.Remove(court); 
            
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa sân (ẩn khỏi danh sách)" });
        }
    }
}
