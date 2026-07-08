import 'package:flutter_test/flutter_test.dart';
import 'package:chroma_inventory_pro/features/formulas/presentation/providers/formulas_provider.dart';
import 'package:chroma_inventory_pro/features/formulas/data/models/formula_model.dart';

void main() {
  group('FormulaBuilderState', () {
    test('totalCost sums item costs', () {
      const state = FormulaBuilderState(
        items: [
          ColorItemModel(
              productId: '1',
              amountUsed: 30,
              unitCost: 0.10,
              bowlIndex: 0),
          ColorItemModel(
              productId: '2',
              amountUsed: 20,
              unitCost: 0.15,
              bowlIndex: 0),
        ],
      );
      // 30 * 0.10 + 20 * 0.15 = 3.00 + 3.00 = 6.00
      expect(state.totalCost, closeTo(6.0, 0.001));
    });

    test('totalWeight sums all amounts', () {
      const state = FormulaBuilderState(
        items: [
          ColorItemModel(
              productId: '1', amountUsed: 30, bowlIndex: 0),
          ColorItemModel(
              productId: '2', amountUsed: 20, bowlIndex: 0),
          ColorItemModel(
              productId: '3', amountUsed: 10, bowlIndex: 1),
        ],
      );
      expect(state.totalWeight, closeTo(60.0, 0.001));
    });

    test('percentInBowl returns correct percentage', () {
      const item1 = ColorItemModel(
          productId: '1', amountUsed: 30, bowlIndex: 0);
      const item2 = ColorItemModel(
          productId: '2', amountUsed: 10, bowlIndex: 0);
      const state =
          FormulaBuilderState(items: [item1, item2]);

      final pct = state.percentInBowl(item1);
      expect(pct, closeTo(75.0, 0.01));
    });

    test('itemsByBowl groups items correctly', () {
      const state = FormulaBuilderState(
        items: [
          ColorItemModel(
              productId: '1', amountUsed: 30, bowlIndex: 0),
          ColorItemModel(
              productId: '2', amountUsed: 20, bowlIndex: 0),
          ColorItemModel(
              productId: '3', amountUsed: 15, bowlIndex: 1),
        ],
      );
      final byBowl = state.itemsByBowl;
      expect(byBowl[0]!.length, 2);
      expect(byBowl[1]!.length, 1);
    });

    test('hasToneMismatch detects warm+cool conflict', () {
      // Warm red (#FF4400) + Cool blue (#0044FF) in same bowl
      const state = FormulaBuilderState(
        items: [
          ColorItemModel(
              productId: '1',
              amountUsed: 30,
              colorHex: '#FF4400',
              bowlIndex: 0),
          ColorItemModel(
              productId: '2',
              amountUsed: 30,
              colorHex: '#0044FF',
              bowlIndex: 0),
        ],
      );
      expect(state.hasToneMismatch(0), isTrue);
    });
  });

  group('ColorItemModel', () {
    test('totalCost calculates correctly', () {
      const item = ColorItemModel(
        productId: '1',
        amountUsed: 50,
        unitCost: 0.12,
        bowlIndex: 0,
      );
      expect(item.totalCost, closeTo(6.0, 0.001));
    });

    test('default unit is grams', () {
      const item =
          ColorItemModel(productId: '1', amountUsed: 30, bowlIndex: 0);
      expect(item.unit, 'g');
    });
  });
}
