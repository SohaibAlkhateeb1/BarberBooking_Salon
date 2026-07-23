using BarberBooking.Application.DTOs.Payment;

namespace BarberBooking.Application.Interfaces;

public interface IPaymentRequestService
{
    Task<PaymentRequestDto> CreatePaymentRequestAsync(Guid barberProfileId, CreatePaymentRequestDto dto);
    Task<List<PaymentRequestDto>> GetMyPaymentRequestsAsync(Guid barberProfileId);
    Task<PaymentRequestDto?> GetPaymentRequestByIdAsync(Guid id);
    Task<List<PaymentRequestWithBarberDto>> GetAllPaymentRequestsAsync(string? status, int page = 1, int pageSize = 20);
    Task<int> GetPendingPaymentRequestsCountAsync();
    Task<PaymentRequestDto> ReviewPaymentRequestAsync(Guid requestId, ReviewPaymentRequestDto dto, Guid reviewedById);
}
