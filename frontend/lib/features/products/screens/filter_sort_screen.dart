import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/providers/product_providers.dart';

class FilterSortScreen extends ConsumerStatefulWidget {
  const FilterSortScreen({super.key});

  @override
  ConsumerState<FilterSortScreen> createState() => _FilterSortScreenState();
}

class _FilterSortScreenState extends ConsumerState<FilterSortScreen> {
  String _selectedSort = 'popular';
  RangeValues _priceRange = const RangeValues(0, 100000);
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedRatings = {};

  final List<Map<String, String>> _sortOptions = [
    {'value': 'popular', 'label': 'Most Popular'},
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'price_low', 'label': 'Price: Low to High'},
    {'value': 'price_high', 'label': 'Price: High to Low'},
    {'value': 'rating', 'label': 'Highest Rated'},
    {'value': 'discount', 'label': 'Best Discount'},
  ];

  final List<String> _categories = [
    'Processors',
    'Graphics Cards',
    'Motherboards',
    'RAM',
    'Storage',
    'Power Supply',
  ];
  final List<String> _brands = [
    'Intel',
    'AMD',
    'NVIDIA',
    'ASUS',
    'MSI',
    'Gigabyte',
    'Corsair',
  ];
  final List<String> _ratings = ['4★ & above', '3★ & above', '2★ & above'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Filter & Sort',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(onPressed: _resetFilters, child: const Text('Reset')),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 100,
            color: Colors.white,
            child: ListView(
              children: [
                _buildSidebarItem(Icons.sort, 'Sort', isSelected: true),
                _buildSidebarItem(
                  Icons.category,
                  'Category',
                  isSelected: false,
                ),
                _buildSidebarItem(
                  Icons.attach_money,
                  'Price',
                  isSelected: false,
                ),
                _buildSidebarItem(Icons.business, 'Brand', isSelected: false),
                _buildSidebarItem(Icons.star, 'Rating', isSelected: false),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort Options
                  const Text(
                    'Sort By',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((option) {
                      final value = option['value']!;
                      final label = option['label']!;
                      final isSelected = _selectedSort == value;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedSort = value);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  const Text(
                    'Price Range',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    labels: RangeLabels(
                      '₹${_priceRange.start.toInt()}',
                      '₹${_priceRange.end.toInt()}',
                    ),
                    onChanged: (values) {
                      setState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Categories
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Brands
                  const Text(
                    'Brands',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _brands.map((brand) {
                      final isSelected = _selectedBrands.contains(brand);
                      return FilterChip(
                        label: Text(brand),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedBrands.add(brand);
                            } else {
                              _selectedBrands.remove(brand);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Ratings
                  const Text(
                    'Customer Rating',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ratings.map((rating) {
                      final isSelected = _selectedRatings.contains(rating);
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Text(rating)],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRatings.add(rating);
                            } else {
                              _selectedRatings.remove(rating);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label, {
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedSort = 'popular';
      _priceRange = const RangeValues(0, 100000);
      _selectedCategories.clear();
      _selectedBrands.clear();
      _selectedRatings.clear();
    });
  }

  void _applyFilters() {
    // Apply filters to product providers
    ref
        .read(productFilterProvider.notifier)
        .updateFilter(
          sortBy: _selectedSort,
          minPrice: _priceRange.start,
          maxPrice: _priceRange.end,
          categories: _selectedCategories.toList(),
          brands: _selectedBrands.toList(),
        );
    context.pop();
  }
}
