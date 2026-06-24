class Service {
  final String id;
  final String title;
  final String description;
  final double? price;
  final String image;
  final List<String> additionalImages;
  final List<String> features;

  const Service({
    required this.id,
    required this.title,
    required this.description,
    this.price,
    required this.image,
    this.additionalImages = const [],
    this.features = const [],
  });

  // Format price for display - handles null safely
  String get formattedPrice {
    if (price == null) {
      return 'Contact for price';
    }
    return '₹${price!.toStringAsFixed(0)}';
  }

  // Check if price is available
  bool get hasPrice => price != null && price! > 0;

  // Safe image getter - returns valid URL or fallback
  String get safeImage => image.isNotEmpty
      ? image
      : 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80';

  String get name => title;
  String get category => title.toLowerCase().contains('install')
      ? 'installation'
      : title.toLowerCase().contains('support') || title.toLowerCase().contains('maintenance')
          ? 'maintenance'
          : 'consultation';
  double get rating => 4.6;
  int get reviewCount => 128;
  String? get duration => '2-4 hours';

  // Get starting price text
  String get priceLabel {
    if (price == null || price! <= 0) {
      return 'Contact for price';
    }
    return 'Starting from ₹${price!.toStringAsFixed(0)}';
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      image: json['image'] as String,
      additionalImages: (json['additionalImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  factory Service.fromSupabase(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      image: json['image_url'] as String? ?? '',
      additionalImages: (json['additional_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'image': image,
      'additionalImages': additionalImages,
      'features': features,
    };
  }

  Service copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? image,
    List<String>? additionalImages,
    List<String>? features,
  }) {
    return Service(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      additionalImages: additionalImages ?? this.additionalImages,
      features: features ?? this.features,
    );
  }
}

// Sample service data with real Unsplash images
class SampleServices {
  static List<Service> get all => [
    const Service(
      id: 'svc_001',
      title: 'CCTV Installation',
      description: 'Professional CCTV camera installation for homes, offices, warehouses, and commercial spaces. Includes IP cameras, dome cameras, and bullet cameras with HD/4K recording.',
      price: 2999,
      image: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=800&q=80',
        'https://images.unsplash.com/photo-1580977251946-b1b5f3ce24f8?w=800&q=80',
      ],
      features: [
        'HD & 4K Camera Options',
        '24/7 Monitoring',
        'Remote Access',
        'Motion Detection',
        'Cloud Storage',
      ],
    ),
    const Service(
      id: 'svc_002',
      title: 'Networking Solutions',
      description: 'End-to-end LAN/WAN setup, structured cabling, Wi-Fi configuration, and network troubleshooting for offices and enterprises.',
      price: 4999,
      image: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=800&q=80',
        'https://images.unsplash.com/photo-1551808525-51a94da548ce?w=800&q=80',
      ],
      features: [
        'Enterprise WiFi',
        'Network Security',
        'Firewall Setup',
        'VPN Configuration',
        '24/7 Support',
      ],
    ),
    const Service(
      id: 'svc_003',
      title: 'Server Installation',
      description: 'Rack server setup, NAS configuration, and data center management for businesses of all sizes.',
      price: 7999,
      image: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1624969862644-791f3dc98927?w=800&q=80',
      ],
      features: [
        'Server Setup',
        'Configuration',
        'Regular Maintenance',
        'Backup Solutions',
        'Performance Tuning',
      ],
    ),
    const Service(
      id: 'svc_004',
      title: 'IT AMC Services',
      description: 'Annual Maintenance Contract covering all your IT hardware — laptops, desktops, printers, and networking equipment.',
      price: null,
      image: 'https://images.unsplash.com/photo-1581092335397-9583eb92d232?w=800&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&q=80',
      ],
      features: [
        'Hardware Maintenance',
        'On-site Support',
        'Remote Assistance',
        'Hardware Repair',
        'Annual Contracts',
      ],
    ),
    const Service(
      id: 'svc_005',
      title: 'Access Control Systems',
      description: 'Biometric, RFID, and keypad access control installation for secured entry management.',
      price: 3499,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
      features: [
        'Biometric Systems',
        'RFID Installation',
        'Keypad Setup',
        'Access Logs',
        'Multi-level Security',
      ],
    ),
    const Service(
      id: 'svc_006',
      title: 'Firewall & Cybersecurity',
      description: 'Network firewall configuration, VPN setup, and cybersecurity audits to protect your business data.',
      price: null,
      image: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800&q=80',
      features: [
        'Firewall Setup',
        'VPN Configuration',
        'Security Audit',
        'Threat Detection',
        'Data Protection',
      ],
    ),
    const Service(
      id: 'svc_007',
      title: 'On-Site IT Support',
      description: 'Professional IT support team for troubleshooting, hardware repair, software installation, and system optimization.',
      price: 2499,
      image: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&q=80',
      features: [
        'Technical Support',
        'Hardware Repair',
        'Software Setup',
        'System Optimization',
        'Quick Response',
      ],
    ),
    const Service(
      id: 'svc_008',
      title: 'Wi-Fi Installation',
      description: 'Professional Wi-Fi network design and installation with optimal coverage and security configuration.',
      price: 3999,
      image: 'https://images.unsplash.com/photo-1606904825846-647eb07f5be2?w=800&q=80',
      features: [
        'Network Design',
        'Installation',
        'Configuration',
        'Signal Optimization',
        'Security Setup',
      ],
    ),
  ];
}
