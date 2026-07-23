import '../../../core/network/api_client.dart';

class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String ticketType;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? attachmentUrl;
  final String? userName;
  final String? userPhone;
  final String? barberName;
  final String? shopName;
  final String? assignedTo;
  final int? rating;
  final String? ratingComment;
  final DateTime createdAt;
  final DateTime? lastReplyAt;
  final DateTime? closedAt;
  final List<TicketReplyModel> replies;

  SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.ticketType,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.attachmentUrl,
    this.userName,
    this.userPhone,
    this.barberName,
    this.shopName,
    this.assignedTo,
    this.rating,
    this.ratingComment,
    required this.createdAt,
    this.lastReplyAt,
    this.closedAt,
    this.replies = const [],
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      ticketType: json['ticketType'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Open',
      priority: json['priority'] ?? 'Normal',
      attachmentUrl: json['attachmentUrl'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      barberName: json['barberName'],
      shopName: json['shopName'],
      assignedTo: json['assignedTo'],
      rating: json['rating'],
      ratingComment: json['ratingComment'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastReplyAt: json['lastReplyAt'] != null ? DateTime.parse(json['lastReplyAt']) : null,
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((r) => TicketReplyModel.fromJson(r))
              .toList() ??
          [],
    );
  }

  String get priorityArabic {
    switch (priority) {
      case 'Urgent':
        return 'عاجلة';
      case 'High':
        return 'عالية';
      default:
        return 'عادية';
    }
  }

  String get statusArabic {
    switch (status) {
      case 'Open':
        return 'مفتوحة';
      case 'In Progress':
        return 'قيد المراجعة';
      case 'Resolved':
        return 'تم الحل';
      case 'Closed':
        return 'مغلقة';
      default:
        return status;
    }
  }

  String get ticketTypeArabic {
    switch (ticketType) {
      case 'Technical':
        return 'مشكلة تقنية';
      case 'Booking':
        return 'مشكلة في الحجز';
      case 'Payment':
        return 'مشكلة بالدفع';
      case 'Barber Complaint':
        return 'شكوى من حلاق';
      case 'Suggestion':
        return 'اقتراح';
      default:
        return ticketType;
    }
  }
}

class TicketReplyModel {
  final String id;
  final String senderRole;
  final String senderName;
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  TicketReplyModel({
    required this.id,
    required this.senderRole,
    required this.senderName,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory TicketReplyModel.fromJson(Map<String, dynamic> json) {
    return TicketReplyModel(
      id: json['id'] ?? '',
      senderRole: json['senderRole'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      attachmentUrl: json['attachmentUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SupportService {
  final ApiClient _api = ApiClient();

  Future<SupportTicketModel> createTicket({
    required String ticketType,
    required String subject,
    required String description,
    String? attachmentUrl,
    String? relatedBookingId,
    String? relatedBarberId,
  }) async {
    final data = <String, dynamic>{
      'ticketType': ticketType,
      'subject': subject,
      'description': description,
    };
    if (attachmentUrl != null) data['attachmentUrl'] = attachmentUrl;
    if (relatedBookingId != null) data['relatedBookingId'] = relatedBookingId;
    if (relatedBarberId != null) data['relatedBarberId'] = relatedBarberId;

    final response = await _api.dio.post('/api/support/tickets', data: data);
    return SupportTicketModel.fromJson(response.data);
  }

  Future<List<SupportTicketModel>> getMyTickets() async {
    final response = await _api.dio.get('/api/support/my-tickets');
    return (response.data as List)
        .map((t) => SupportTicketModel.fromJson(t))
        .toList();
  }

  Future<SupportTicketModel> getTicketDetail(String ticketId) async {
    final response = await _api.dio.get('/api/support/tickets/$ticketId');
    return SupportTicketModel.fromJson(response.data);
  }

  Future<TicketReplyModel> addReply({
    required String ticketId,
    required String message,
    String? attachmentUrl,
  }) async {
    final data = <String, dynamic>{'message': message};
    if (attachmentUrl != null) data['attachmentUrl'] = attachmentUrl;

    final response = await _api.dio.post(
      '/api/support/tickets/$ticketId/reply',
      data: data,
    );
    return TicketReplyModel.fromJson(response.data);
  }

  Future<bool> rateTicket({
    required String ticketId,
    required int rating,
    String? comment,
  }) async {
    final data = <String, dynamic>{'rating': rating};
    if (comment != null) data['comment'] = comment;

    try {
      await _api.dio.post('/api/support/tickets/$ticketId/rate', data: data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
