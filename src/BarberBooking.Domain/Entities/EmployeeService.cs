namespace BarberBooking.Domain.Entities;

public class EmployeeService : BaseEntity
{
    public Guid EmployeeId { get; set; }
    public Guid BarberServiceId { get; set; }

    public BarberEmployee Employee { get; set; } = null!;
    public BarberService BarberService { get; set; } = null!;
}
