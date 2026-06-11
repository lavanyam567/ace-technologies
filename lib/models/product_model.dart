class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final double rating;
  final String image;
  final List<String> additionalImages;
  final bool isOutOfStock;
  final int discount;
  final String category;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.image,
    this.additionalImages = const [],
    this.isOutOfStock = false,
    this.discount = 0,
    required this.category,
    this.description = '',
  });

  // Calculate discounted price
  double get discountedPrice {
    if (originalPrice != null && originalPrice! > 0) {
      return originalPrice! - (originalPrice! * discount / 100);
    }
    return price;
  }

  // Check if product has discount
  bool get hasDiscount => discount > 0;

  // Format price for display
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  
  String get formattedOriginalPrice => originalPrice != null 
      ? '₹${originalPrice!.toStringAsFixed(0)}' 
      : '';

  // Calculate savings amount
  double get savings => (originalPrice != null && originalPrice! > price) 
      ? (originalPrice! - price) 
      : 0;

  // Format savings for display
  String get formattedSavings => savings > 0 
      ? '₹${savings.toStringAsFixed(0)}' 
      : '';

  // Safe formatted price - never shows NaN
  String get safeFormattedPrice => price > 0 
      ? '₹${price.toStringAsFixed(0)}' 
      : 'Contact for Price';

  // Safe image getter - returns valid URL or fallback
  String get safeImage => image.isNotEmpty
      ? image
      : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null 
          ? (json['originalPrice'] as num).toDouble() 
          : null,
      rating: (json['rating'] as num).toDouble(),
      image: json['image'] as String,
      additionalImages: (json['additionalImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isOutOfStock: json['isOutOfStock'] as bool? ?? false,
      discount: json['discount'] as int? ?? 0,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  factory Product.fromSupabase(Map<String, dynamic> json) {
    final stock = json['stock'] as int? ?? 0;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      rating: (json['rating'] as num? ?? 4.5).toDouble(),
      image: json['image_url'] as String? ?? '',
      additionalImages: (json['additional_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isOutOfStock: stock <= 0,
      discount: json['discount'] as int? ?? 0,
      category: json['category'] as String? ?? 'All',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'originalPrice': originalPrice,
      'rating': rating,
      'image': image,
      'additionalImages': additionalImages,
      'isOutOfStock': isOutOfStock,
      'discount': discount,
      'category': category,
      'description': description,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    double? originalPrice,
    double? rating,
    String? image,
    List<String>? additionalImages,
    bool? isOutOfStock,
    int? discount,
    String? category,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      image: image ?? this.image,
      additionalImages: additionalImages ?? this.additionalImages,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      discount: discount ?? this.discount,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}

// Sample product data with real Unsplash images
class SampleProducts {
  static List<Product> get all => [
    // --- PROCESSORS ---
    const Product(
      id: 'proc_001',
      name: 'Intel Core i9-13900K',
      brand: 'Intel',
      price: 42999,
      originalPrice: 49999,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=600&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80',
        'https://images.unsplash.com/photo-1562408590-e32931084e23?w=600&q=80',
      ],
      discount: 14,
      category: 'Processors',
    ),
    const Product(
      id: 'proc_002',
      name: 'AMD Ryzen 9 7950X',
      brand: 'AMD',
      price: 57999,
      originalPrice: 64999,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1555617981-dac3772603b6?w=600&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1561736778-92e52a7769ef?w=600&q=80',
      ],
      discount: 11,
      category: 'Processors',
    ),
    const Product(
      id: 'proc_003',
      name: 'Intel Core i7-12700',
      brand: 'Intel',
      price: 32999,
      originalPrice: 38999,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80',
      discount: 15,
      category: 'Processors',
    ),
    const Product(
      id: 'proc_004',
      name: 'AMD Ryzen 5 7600X',
      brand: 'AMD',
      price: 21999,
      originalPrice: 26999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1561736778-92e52a7769ef?w=600&q=80',
      discount: 19,
      isOutOfStock: true,
      category: 'Processors',
    ),
    const Product(
      id: 'proc_005',
      name: 'Intel Core i5-13400',
      brand: 'Intel',
      price: 18999,
      originalPrice: 22999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1562408590-e32931084e23?w=600&q=80',
      discount: 17,
      category: 'Processors',
    ),
    // --- LAPTOPS ---
    const Product(
      id: 'lap_001',
      name: 'HP EliteBook 840 G10',
      brand: 'HP',
      price: 89999,
      originalPrice: 104999,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1484788984921-03950022c9ef?w=600&q=80',
      ],
      discount: 14,
      category: 'Laptops',
    ),
    const Product(
      id: 'lap_002',
      name: 'Dell Latitude 5540',
      brand: 'Dell',
      price: 79999,
      originalPrice: 91999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=600&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=600&q=80',
      ],
      discount: 13,
      category: 'Laptops',
    ),
    const Product(
      id: 'lap_003',
      name: 'Lenovo ThinkPad X1 Carbon',
      brand: 'Lenovo',
      price: 112999,
      originalPrice: 129999,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=600&q=80',
      discount: 13,
      category: 'Laptops',
    ),
    const Product(
      id: 'lap_004',
      name: 'HP ProBook 450 G10',
      brand: 'HP',
      price: 69999,
      originalPrice: 81999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1484788984921-03950022c9ef?w=600&q=80',
      discount: 15,
      category: 'Laptops',
    ),
    const Product(
      id: 'lap_005',
      name: 'Dell Inspiron 15',
      brand: 'Dell',
      price: 59999,
      originalPrice: 69999,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=600&q=80',
      discount: 14,
      category: 'Laptops',
    ),
    const Product(
      id: 'lap_006',
      name: 'Lenovo IdeaPad Slim 5',
      brand: 'Lenovo',
      price: 52999,
      originalPrice: 61999,
      rating: 4.3,
      image: 'https://images.unsplash.com/photo-1611078489935-0cb964de46d6?w=600&q=80',
      discount: 15,
      category: 'Laptops',
    ),
    // --- NETWORKING DEVICES ---
    const Product(
      id: 'net_001',
      name: 'Cisco Catalyst 2960 Switch',
      brand: 'Cisco',
      price: 34999,
      originalPrice: 41999,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=600&q=80',
      additionalImages: [
        'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=600&q=80',
      ],
      discount: 17,
      category: 'Networking',
    ),
    const Product(
      id: 'net_002',
      name: 'TP-Link 24-Port Gigabit Switch',
      brand: 'TP-Link',
      price: 7999,
      originalPrice: 9999,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=600&q=80',
      discount: 20,
      category: 'Networking',
    ),
    const Product(
      id: 'net_003',
      name: 'Cisco RV340 Router',
      brand: 'Cisco',
      price: 18999,
      originalPrice: 22999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1606904825846-647eb07f5be2?w=600&q=80',
      discount: 17,
      category: 'Networking',
    ),
    const Product(
      id: 'net_004',
      name: 'TP-Link Archer AX73 Wi-Fi 6 Router',
      brand: 'TP-Link',
      price: 8999,
      originalPrice: 11999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1593642634367-d91a135587b5?w=600&q=80',
      discount: 25,
      category: 'Networking',
    ),
    const Product(
      id: 'net_005',
      name: 'D-Link 8-Port PoE Switch',
      brand: 'D-Link',
      price: 6499,
      originalPrice: 7999,
      rating: 4.3,
      image: 'https://images.unsplash.com/photo-1551808525-51a94da548ce?w=600&q=80',
      discount: 19,
      isOutOfStock: true,
      category: 'Networking',
    ),
    // --- PRINTERS ---
    const Product(
      id: 'prt_001',
      name: 'HP LaserJet Pro M404dn',
      brand: 'HP',
      price: 24999,
      originalPrice: 29999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1612198188060-c7c2a3b66eae?w=600&q=80',
      discount: 17,
      category: 'Printers',
    ),
    const Product(
      id: 'prt_002',
      name: 'Epson EcoTank L3250',
      brand: 'Epson',
      price: 13999,
      originalPrice: 16999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1586339949216-35c2747cc36d?w=600&q=80',
      discount: 18,
      category: 'Printers',
    ),
    const Product(
      id: 'prt_003',
      name: 'Canon PIXMA G3020',
      brand: 'Canon',
      price: 11499,
      originalPrice: 13999,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1575330933415-a9f9e8de1e3c?w=600&q=80',
      discount: 18,
      category: 'Printers',
    ),
    const Product(
      id: 'prt_004',
      name: 'HP Color LaserJet Pro M254dw',
      brand: 'HP',
      price: 32999,
      originalPrice: 39999,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=600&q=80',
      discount: 18,
      category: 'Printers',
    ),
    const Product(
      id: 'prt_005',
      name: 'Epson WorkForce WF-2930',
      brand: 'Epson',
      price: 16999,
      originalPrice: 19999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1601445638532-d98e42ba9a85?w=600&q=80',
      discount: 15,
      category: 'Printers',
    ),
    // --- CAMERAS ---
    const Product(
      id: 'cam_001',
      name: 'Hikvision 4MP IP Camera',
      brand: 'Hikvision',
      price: 4999,
      originalPrice: 6500,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=600&q=80',
      discount: 23,
      category: 'CCTV Cameras',
    ),
    const Product(
      id: 'cam_002',
      name: 'CP Plus Dome Camera',
      brand: 'CP Plus',
      price: 3499,
      originalPrice: 4200,
      rating: 4.2,
      image: 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=600&q=80',
      discount: 17,
      category: 'CCTV Cameras',
    ),
    // --- FIRE ALARMS ---
    const Product(
      id: 'fire_001',
      name: 'Honeywell Smoke Detector',
      brand: 'Honeywell',
      price: 2199,
      originalPrice: 2800,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=600&q=80',
      discount: 21,
      category: 'Fire Alarms',
    ),
    const Product(
      id: 'fire_002',
      name: 'Bosch Fire Alarm Panel',
      brand: 'Bosch',
      price: 15999,
      originalPrice: 19000,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1555664424-778a1e5e1b48?w=600&q=80',
      discount: 16,
      category: 'Fire Alarms',
    ),
    // --- DOOR ACCESS ---
    const Product(
      id: 'door_001',
      name: 'ZKTeco Biometric Door Lock',
      brand: 'ZKTeco',
      price: 8999,
      originalPrice: 11000,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600&q=80',
      discount: 18,
      category: 'Door Access',
    ),
    const Product(
      id: 'door_002',
      name: 'HID RFID Card Reader',
      brand: 'HID',
      price: 6499,
      originalPrice: 7800,
      rating: 4.3,
      image: 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=600&q=80',
      discount: 17,
      isOutOfStock: true,
      category: 'Door Access',
    ),
    // --- RAM ---
    const Product(
      id: 'ram_001',
      name: 'Kingston 16GB DDR4 3200MHz',
      brand: 'Kingston',
      price: 3299,
      originalPrice: 4000,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=600&q=80',
      discount: 18,
      category: 'RAM',
    ),
    const Product(
      id: 'ram_002',
      name: 'Corsair Vengeance 32GB DDR5',
      brand: 'Corsair',
      price: 8999,
      originalPrice: 10500,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=600&q=80',
      discount: 14,
      category: 'RAM',
    ),
    // --- HARD DISK ---
    const Product(
      id: 'hdd_001',
      name: 'Seagate Barracuda 2TB HDD',
      brand: 'Seagate',
      price: 4299,
      originalPrice: 5200,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1531492746076-161ca9bcad58?w=600&q=80',
      discount: 17,
      category: 'Hard Disk',
    ),
    const Product(
      id: 'hdd_002',
      name: 'WD Blue 1TB SSD',
      brand: 'WD',
      price: 6999,
      originalPrice: 8500,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1597138804456-e7dca7f59d54?w=600&q=80',
      discount: 18,
      category: 'Hard Disk',
    ),
    // --- KEYBOARD ---
    const Product(
      id: 'kb_001',
      name: 'Logitech MK470 Wireless Keyboard',
      brand: 'Logitech',
      price: 2799,
      originalPrice: 3500,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600&q=80',
      discount: 20,
      category: 'Keyboard',
    ),
    const Product(
      id: 'kb_002',
      name: 'HyperX Alloy Origins Mechanical',
      brand: 'HyperX',
      price: 7499,
      originalPrice: 9000,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?w=600&q=80',
      discount: 17,
      category: 'Keyboard',
    ),
    // --- MOUSE ---
    const Product(
      id: 'mouse_001',
      name: 'Logitech MX Master 3',
      brand: 'Logitech',
      price: 7999,
      originalPrice: 9500,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=600&q=80',
      discount: 16,
      category: 'Mouse',
    ),
    const Product(
      id: 'mouse_002',
      name: 'Razer DeathAdder V3',
      brand: 'Razer',
      price: 5499,
      originalPrice: 6800,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=600&q=80',
      discount: 19,
      category: 'Mouse',
    ),
    // --- MONITOR ---
    const Product(
      id: 'mon_001',
      name: 'LG 27" 4K IPS Monitor',
      brand: 'LG',
      price: 32999,
      originalPrice: 40000,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=600&q=80',
      discount: 18,
      category: 'Monitor',
    ),
    const Product(
      id: 'mon_002',
      name: 'Dell 24" FHD 165Hz Gaming Monitor',
      brand: 'Dell',
      price: 18999,
      originalPrice: 23000,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1585792180666-f7347c490ee2?w=600&q=80',
      discount: 17,
      category: 'Monitor',
    ),
    // --- PENDRIVE ---
    const Product(
      id: 'pend_001',
      name: 'SanDisk Cruzer Blade 32GB',
      brand: 'SanDisk',
      price: 399,
      originalPrice: 599,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=600&q=80',
      discount: 33,
      category: 'Pendrive',
    ),
    const Product(
      id: 'pend_002',
      name: 'Kingston DataTraveler 64GB',
      brand: 'Kingston',
      price: 599,
      originalPrice: 799,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=600&q=80',
      discount: 25,
      category: 'Pendrive',
    ),
    const Product(
      id: 'pend_003',
      name: 'Transcend JetFlash 128GB',
      brand: 'Transcend',
      price: 899,
      originalPrice: 1299,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=600&q=80',
      discount: 31,
      category: 'Pendrive',
    ),
    // --- TV ---
    const Product(
      id: 'tv_001',
      name: 'Sony Bravia 55" 4K Smart TV',
      brand: 'Sony',
      price: 49999,
      originalPrice: 64999,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=600&q=80',
      discount: 23,
      category: 'TV',
    ),
    const Product(
      id: 'tv_002',
      name: 'LG OLED 55" 4K TV',
      brand: 'LG',
      price: 69999,
      originalPrice: 89999,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=600&q=80',
      discount: 22,
      category: 'TV',
    ),
    const Product(
      id: 'tv_003',
      name: 'Samsung 43" FHD Smart TV',
      brand: 'Samsung',
      price: 24999,
      originalPrice: 32999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=600&q=80',
      discount: 24,
      category: 'TV',
    ),
    // --- DVR ---
    const Product(
      id: 'dvr_001',
      name: 'Hikvision 16-Channel DVR',
      brand: 'Hikvision',
      price: 18999,
      originalPrice: 24999,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1591076482161-42ce6da69f67?w=600&q=80',
      discount: 24,
      category: 'DVR',
    ),
    const Product(
      id: 'dvr_002',
      name: 'CP Plus 8-Channel DVR',
      brand: 'CP Plus',
      price: 11999,
      originalPrice: 15999,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1591076482161-42ce6da69f67?w=600&q=80',
      discount: 25,
      category: 'DVR',
    ),
    const Product(
      id: 'dvr_003',
      name: 'Dahua 4-Channel DVR',
      brand: 'Dahua',
      price: 7999,
      originalPrice: 10999,
      rating: 4.3,
      image: 'https://images.unsplash.com/photo-1591076482161-42ce6da69f67?w=600&q=80',
      discount: 27,
      category: 'DVR',
    ),
    // --- NVR ---
    const Product(
      id: 'nvr_001',
      name: 'Hikvision 16-Channel NVR',
      brand: 'Hikvision',
      price: 24999,
      originalPrice: 32999,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      discount: 24,
      category: 'NVR',
    ),
    const Product(
      id: 'nvr_002',
      name: 'Uniview 8-Channel NVR',
      brand: 'Uniview',
      price: 16999,
      originalPrice: 22999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      discount: 26,
      category: 'NVR',
    ),
    const Product(
      id: 'nvr_003',
      name: 'CP Plus 4-Channel NVR',
      brand: 'CP Plus',
      price: 10999,
      originalPrice: 14999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      discount: 27,
      category: 'NVR',
    ),
    // --- PROJECTOR ---
    const Product(
      id: 'proj_001',
      name: 'Epson EB-FH52 4000L Projector',
      brand: 'Epson',
      price: 34999,
      originalPrice: 44999,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1596933247274-e55ff1ca7a42?w=600&q=80',
      discount: 22,
      category: 'Projector',
    ),
    const Product(
      id: 'proj_002',
      name: 'Sony VPL-FHZ70 5000L Projector',
      brand: 'Sony',
      price: 59999,
      originalPrice: 74999,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1596933247274-e55ff1ca7a42?w=600&q=80',
      discount: 20,
      category: 'Projector',
    ),
    const Product(
      id: 'proj_003',
      name: 'BenQ MH535 3600L Projector',
      brand: 'BenQ',
      price: 27999,
      originalPrice: 35999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1596933247274-e55ff1ca7a42?w=600&q=80',
      discount: 22,
      category: 'Projector',
    ),
    // --- CABLES (3+1) ---
    const Product(
      id: 'cable_001',
      name: 'Cat6 Ethernet Cable 100m (3+1)',
      brand: 'Schneider',
      price: 4999,
      originalPrice: 6999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1621905251297-48416dedd119?w=600&q=80',
      discount: 29,
      category: 'Cables (3+1)',
    ),
    const Product(
      id: 'cable_002',
      name: 'Cat5e Ethernet Cable 305m (3+1)',
      brand: 'D-Link',
      price: 3499,
      originalPrice: 4999,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1621905251297-48416dedd119?w=600&q=80',
      discount: 30,
      category: 'Cables (3+1)',
    ),
    const Product(
      id: 'cable_003',
      name: 'Cat7 Ethernet Cable 305m (3+1)',
      brand: 'TP-Link',
      price: 5999,
      originalPrice: 7999,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1621905251297-48416dedd119?w=600&q=80',
      discount: 25,
      category: 'Cables (3+1)',
    ),
    // --- TELEPHONING SOLUTIONS - IP PBX ---
    const Product(
      id: 'ipbax_001',
      name: 'Avaya IP PBX 100-200 Users',
      brand: 'Avaya',
      price: 89999,
      originalPrice: 119999,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=600&q=80',
      discount: 25,
      category: 'Telephoning Solutions',
    ),
    const Product(
      id: 'ipbax_002',
      name: 'Cisco IP PBX 50-100 Users',
      brand: 'Cisco',
      price: 59999,
      originalPrice: 79999,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=600&q=80',
      discount: 25,
      category: 'Telephoning Solutions',
    ),
    const Product(
      id: 'ipbax_003',
      name: 'Alcatel-Lucent IP PBX 20-50 Users',
      brand: 'Alcatel-Lucent',
      price: 34999,
      originalPrice: 49999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=600&q=80',
      discount: 30,
      category: 'Telephoning Solutions',
    ),
    // --- TELEPHONING SOLUTIONS - EP PBX ---
    const Product(
      id: 'epbax_001',
      name: 'Panasonic EP PBX KX-TEM824',
      brand: 'Panasonic',
      price: 49999,
      originalPrice: 64999,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=600&q=80',
      discount: 23,
      category: 'Telephoning Solutions',
    ),
    const Product(
      id: 'epbax_002',
      name: 'NEC EP PBX SL2100',
      brand: 'NEC',
      price: 39999,
      originalPrice: 54999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=600&q=80',
      discount: 27,
      category: 'Telephoning Solutions',
    ),
    const Product(
      id: 'epbax_003',
      name: 'Avaya EP PBX Communication Manager',
      brand: 'Avaya',
      price: 29999,
      originalPrice: 39999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=600&q=80',
      discount: 25,
      category: 'Telephoning Solutions',
    ),
    // --- ACCESS POINT ---
    const Product(
      id: 'ap_001',
      name: 'Cisco Aironet Access Point',
      brand: 'Cisco',
      price: 19999,
      originalPrice: 26999,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      discount: 26,
      category: 'Access Point',
    ),
    const Product(
      id: 'ap_002',
      name: 'Arista Access Point WiFi 6',
      brand: 'Arista',
      price: 14999,
      originalPrice: 19999,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      discount: 25,
      category: 'Access Point',
    ),
    const Product(
      id: 'ap_003',
      name: 'TP-Link EAP245 Access Point',
      brand: 'TP-Link',
      price: 8999,
      originalPrice: 11999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
      discount: 25,
      category: 'Access Point',
    ),
  ];

  static List<Product> getByCategory(String category) {
    return all.where((p) => p.category == category).toList();
  }

  static List<Product> get featured => all.take(6).toList();
}
