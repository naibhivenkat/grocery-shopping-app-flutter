import 'package:flutter/material.dart';

class ServiceCatalogItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class ServiceCatalog {
  // ✅ Frontend-only list (20+)
  static const List<ServiceCatalogItem> items = [
    ServiceCatalogItem(id: "doctor", name: "Doctor", icon: Icons.local_hospital, color: Color(0xFFEF4444)),
    ServiceCatalogItem(id: "lawyer", name: "Lawyer", icon: Icons.gavel, color: Color(0xFF0EA5E9)),
    ServiceCatalogItem(id: "plumber", name: "Plumber", icon: Icons.plumbing, color: Color(0xFF6366F1)),
    ServiceCatalogItem(id: "electrician", name: "Electrician", icon: Icons.electrical_services, color: Color(0xFFF59E0B)),
    ServiceCatalogItem(id: "tutor", name: "Tutor", icon: Icons.school, color: Color(0xFF22C55E)),
    ServiceCatalogItem(id: "carpenter", name: "Carpenter", icon: Icons.handyman, color: Color(0xFF8B5CF6)),
    ServiceCatalogItem(id: "painter", name: "Painter", icon: Icons.format_paint, color: Color(0xFFEC4899)),
    ServiceCatalogItem(id: "mechanic", name: "Mechanic", icon: Icons.car_repair, color: Color(0xFF14B8A6)),
    ServiceCatalogItem(id: "cleaning", name: "Cleaning", icon: Icons.cleaning_services, color: Color(0xFF06B6D4)),
    ServiceCatalogItem(id: "photographer", name: "Photographer", icon: Icons.camera_alt, color: Color(0xFF3B82F6)),
    ServiceCatalogItem(id: "chef", name: "Chef", icon: Icons.restaurant, color: Color(0xFFF97316)),
    ServiceCatalogItem(id: "salon", name: "Salon", icon: Icons.content_cut, color: Color(0xFFDB2777)),
    ServiceCatalogItem(id: "fitness", name: "Fitness Trainer", icon: Icons.fitness_center, color: Color(0xFF10B981)),
    ServiceCatalogItem(id: "yoga", name: "Yoga Instructor", icon: Icons.self_improvement, color: Color(0xFF22C55E)),
    ServiceCatalogItem(id: "vet", name: "Veterinary", icon: Icons.pets, color: Color(0xFF84CC16)),
    ServiceCatalogItem(id: "it_support", name: "IT Support", icon: Icons.support_agent, color: Color(0xFF0EA5E9)),
    ServiceCatalogItem(id: "home_nurse", name: "Home Nurse", icon: Icons.medical_services, color: Color(0xFFEF4444)),
    ServiceCatalogItem(id: "delivery", name: "Courier", icon: Icons.local_shipping, color: Color(0xFF64748B)),
    ServiceCatalogItem(id: "astrologer", name: "Astrologer", icon: Icons.stars, color: Color(0xFF9333EA)),
    ServiceCatalogItem(id: "architect", name: "Architect", icon: Icons.apartment, color: Color(0xFF1D4ED8)),
    ServiceCatalogItem(id: "interior", name: "Interior Design", icon: Icons.chair_alt, color: Color(0xFFB45309)),
    ServiceCatalogItem(id: "gardener", name: "Gardener", icon: Icons.grass, color: Color(0xFF16A34A)),
  ];

  static ServiceCatalogItem? byId(String id) {
    try {
      return items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
