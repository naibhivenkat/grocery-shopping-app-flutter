class ServiceAuthUser {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String role; // provider or requester
  final String serviceCategoryId;
  final String location;

  ServiceAuthUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    required this.serviceCategoryId,
    required this.location,
  });

  factory ServiceAuthUser.fromJson(Map<String, dynamic> j) => ServiceAuthUser(
        uid: j["uid"] ?? "",
        name: j["name"] ?? "",
        email: j["email"] ?? "",
        mobile: j["mobile"] ?? "",
        role: j["role"] ?? "provider",
        serviceCategoryId: j["service_category_id"] ?? "",
        location: j["location"] ?? "",
      );
}

class ProviderService {
  final String id;
  final String providerId;
  final String serviceCategoryId;
  final String title;
  final String description;
  final double fixedPrice;
  final String pricingUnit; // per_hour / per_minute / per_day / fixed

  ProviderService({
    required this.id,
    required this.providerId,
    required this.serviceCategoryId,
    required this.title,
    required this.description,
    required this.fixedPrice,
    required this.pricingUnit,
  });

  factory ProviderService.fromJson(Map<String, dynamic> j) => ProviderService(
        id: j["id"] ?? "",
        providerId: j["provider_id"] ?? "",
        serviceCategoryId: j["service_category_id"] ?? "",
        title: j["title"] ?? "",
        description: j["description"] ?? "",
        fixedPrice: (j["fixed_price"] ?? 0).toDouble(),
        pricingUnit: j["pricing_unit"] ?? "fixed",
      );
}

class Booking {
  final String id;
  final String providerId;
  final String requesterId;
  final String serviceId;
  final String slotDate; // YYYY-MM-DD
  final String slotTime; // HH:mm
  final String status; // incoming/accepted/rejected/started/completed/cancelled
  final double totalCost;
  final double commission;
  final double discount;

  Booking({
    required this.id,
    required this.providerId,
    required this.requesterId,
    required this.serviceId,
    required this.slotDate,
    required this.slotTime,
    required this.status,
    required this.totalCost,
    required this.commission,
    required this.discount,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j["id"] ?? "",
        providerId: j["provider_id"] ?? "",
        requesterId: j["requester_id"] ?? "",
        serviceId: j["service_id"] ?? "",
        slotDate: j["slot_date"] ?? "",
        slotTime: j["slot_time"] ?? "",
        status: j["status"] ?? "incoming",
        totalCost: (j["total_cost"] ?? 0).toDouble(),
        commission: (j["commission"] ?? 0).toDouble(),
        discount: (j["discount"] ?? 0).toDouble(),
      );
}

class RatingReview {
  final String id;
  final String providerId;
  final String serviceId;
  final double rating;
  final String review;
  final String createdAt;

  RatingReview({
    required this.id,
    required this.providerId,
    required this.serviceId,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory RatingReview.fromJson(Map<String, dynamic> j) => RatingReview(
        id: j["id"] ?? "",
        providerId: j["provider_id"] ?? "",
        serviceId: j["service_id"] ?? "",
        rating: (j["rating"] ?? 0).toDouble(),
        review: j["review"] ?? "",
        createdAt: j["created_at"] ?? "",
      );
}
