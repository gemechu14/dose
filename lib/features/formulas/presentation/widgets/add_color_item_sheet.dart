import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/formula_model.dart';
import '../providers/formulas_provider.dart';

class AddColorItemSheet extends ConsumerStatefulWidget {
  /// If provided, the item is added directly to this bowl (no bowl picker).
  final int? bowlIndex;

  const AddColorItemSheet({super.key, this.bowlIndex});

  @override
  ConsumerState<AddColorItemSheet> createState() =>
      _AddColorItemSheetState();
}

class _AddColorItemSheetState extends ConsumerState<AddColorItemSheet> {
  final _productNameCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '30');
  String _selectedUnit = 'g';
  late int _selectedBowl;
  String? _selectedHex;

  final List<({String name, Color color, String hex})> _quickColors = [
    (name: 'Warm Brown', color: const Color(0xFF8B4513), hex: '8B4513'),
    (name: 'Ash Blonde', color: const Color(0xFFD4C4A8), hex: 'D4C4A8'),
    (name: 'Copper Red', color: const Color(0xFFB87333), hex: 'B87333'),
    (name: 'Jet Black', color: const Color(0xFF2C2C2C), hex: '2C2C2C'),
    (name: 'Platinum', color: const Color(0xFFE8E4D9), hex: 'E8E4D9'),
    (name: 'Violet', color: const Color(0xFF7B2D8B), hex: '7B2D8B'),
    (name: 'Strawberry', color: const Color(0xFFFF6B6B), hex: 'FF6B6B'),
    (name: 'Caramel', color: const Color(0xFFC68642), hex: 'C68642'),
    (name: 'Teal', color: const Color(0xFF008080), hex: '008080'),
    (name: 'Golden', color: const Color(0xFFFFD700), hex: 'FFD700'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedBowl = widget.bowlIndex ?? 0;
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _productCodeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (_productNameCtrl.text.isEmpty || amount <= 0) return;

    ref.read(formulaBuilderProvider.notifier).addItem(
          ColorItemModel(
            productId:
                DateTime.now().millisecondsSinceEpoch.toString(),
            productName: _productNameCtrl.text,
            productCode: _productCodeCtrl.text.isNotEmpty
                ? _productCodeCtrl.text
                : null,
            colorHex: _selectedHex,
            amountUsed: amount,
            unit: _selectedUnit,
            bowlIndex: _selectedBowl,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Add Product', style: AppTextStyles.headingMd),
            const SizedBox(height: 20),

            // Color swatches
            Text('Select Shade', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickColors.map((c) {
                final isSelected = _selectedHex == c.hex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedHex = c.hex;
                    if (_productNameCtrl.text.isEmpty) {
                      _productNameCtrl.text = c.name;
                    }
                  }),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2.5)
                          : Border.all(
                              color: AppColors.border, width: 1),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Product name
            Text('Product Name', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _productNameCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. Wella 6/3 Dark Blonde'),
            ),
            const SizedBox(height: 12),

            // Code + amount + unit row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _productCodeCtrl,
                        decoration:
                            const InputDecoration(hintText: '6/3'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: '30'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 14)),
                        items: const [
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(
                              value: 'ml', child: Text('ml')),
                          DropdownMenuItem(
                              value: 'oz', child: Text('oz')),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedUnit = v ?? 'g'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bowl picker (hidden if bowlIndex was provided)
            if (widget.bowlIndex == null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Bowl:', style: AppTextStyles.label),
                  const SizedBox(width: 12),
                  ...List.generate(3, (i) {
                    final isSelected = _selectedBowl == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedBowl = i),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
            const SizedBox(height: 24),

            AppButton(
              label: 'Add to Formula',
              onPressed: _add,
            ),
          ],
        ),
      ),
    );
  }
}
