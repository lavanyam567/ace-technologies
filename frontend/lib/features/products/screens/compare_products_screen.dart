import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../widgets/cached_image.dart';
import '../../products/providers/product_providers.dart';

class CompareProductsScreen extends ConsumerWidget {
  const CompareProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(compareProductsProvider);
    final allProducts = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Compare Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (selectedIds.isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(compareProductsProvider.notifier)
                      .clearCompare();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selected Products
          if (selectedIds.isNotEmpty)
            Container(
              height: 180,
              color: Colors.white,
              child: Row(
                children: selectedIds.map((id) {
                  final product = allProducts.firstWhere(
                    (p) => p.id == id,
                    orElse: () => allProducts.first,
                  );
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 80,
                                  color: Colors.grey.shade100,
                                  child: AceImage(
                                    url: product.image,
                                    width: double.infinity,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    try {
                                      await ref
                                          .read(
                                            compareProductsProvider.notifier,
                                          )
                                          .removeFromCompare(id);
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error.toString()),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            CurrencyUtils.formatPrice(product.price),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Compare Button
          if (selectedIds.length >= 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showCompareDetails(context, ref, allProducts, selectedIds);
                  },
                  child: const Text('Compare Now'),
                ),
              ),
            ),

          // Available Products to Add
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Add products to compare',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...allProducts.where((p) => !selectedIds.contains(p.id)).map((
                  product,
                ) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade100,
                            child: AceImage(
                              url: product.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                product.brand,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: selectedIds.length < 4
                              ? () async {
                                  try {
                                    await ref
                                        .read(compareProductsProvider.notifier)
                                        .addToCompare(product.id);
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.toString())),
                                    );
                                  }
                                }
                              : null,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompareDetails(
    BuildContext context,
    WidgetRef ref,
    List<Product> allProducts,
    List<String> selectedIds,
  ) {
    final products = selectedIds.map<Product>((id) {
      return allProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => allProducts.first,
      );
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Product Comparison',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade200),
                  columnWidths: {
                    for (int i = 0; i <= products.length; i++)
                      i: const FlexColumnWidth(1),
                  },
                  children: [
                    _buildTableRow(
                      'Feature',
                      products.map((p) => p.name).toList(),
                      isHeader: true,
                    ),
                    _buildTableRow(
                      'Price',
                      products
                          .map((p) => CurrencyUtils.formatPrice(p.price))
                          .toList(),
                    ),
                    _buildTableRow(
                      'Brand',
                      products.map((p) => p.brand).toList(),
                    ),
                    _buildTableRow(
                      'Rating',
                      products.map<String>((p) => '${p.rating} stars').toList(),
                    ),
                    _buildTableRow(
                      'Category',
                      products.map((p) => p.category).toList(),
                    ),
                    _buildTableRow(
                      'Description',
                      products
                          .map(
                            (p) =>
                                p.description.isEmpty ? p.name : p.description,
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String label,
    List<String> values, {
    bool isHeader = false,
  }) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: isHeader
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        ...values.map(
          (value) => Container(
            padding: const EdgeInsets.all(12),
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
