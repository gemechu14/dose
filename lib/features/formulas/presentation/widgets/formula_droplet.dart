import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/mix_models.dart';

// ─── FormulaDroplet ───────────────────────────────────────────────────────────
//
// Erlenmeyer-style flask with stacked color layers.
// • COLOR + TONER-with-hex → liquid layers (bottom = first product, top = last)
// • DEVELOPER / TREATMENT → listed below the flask only
//
// ─────────────────────────────────────────────────────────────────────────────

class FormulaDroplet extends StatelessWidget {
  final List<DropletItem> items;
  final double flaskWidth;
  final double flaskHeight;

  const FormulaDroplet({
    super.key,
    required this.items,
    this.flaskWidth = 90,
    this.flaskHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    final flaskItems =
        items.where((d) => d.goesInFlask).toList();
    final belowItems =
        items.where((d) => !d.goesInFlask && d.amount > 0).toList();

    final totalFlaskAmount =
        flaskItems.fold(0.0, (s, d) => s + d.amount);

    // Visual fill ratio keeps small mixes visible.
    const capacity = 500.0;
    final fillRatio =
        math.min(1.0, totalFlaskAmount / capacity);
    final visualFill =
        flaskItems.isEmpty ? 0.0 : math.max(0.12, math.pow(fillRatio, 0.62).toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Flask ──────────────────────────────────────────────────────
        SizedBox(
          width: flaskWidth + 80, // room for callouts
          height: flaskHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Flask container
              Positioned(
                left: 40,
                top: 0,
                child: CustomPaint(
                  size: Size(flaskWidth, flaskHeight),
                  painter: _FlaskPainter(
                    items: flaskItems,
                    visualFill: visualFill,
                    totalAmount: totalFlaskAmount,
                  ),
                ),
              ),
              // Callouts (alternating left / right)
              ...List.generate(flaskItems.length, (i) {
                final item = flaskItems[i];
                final onLeft = i.isEven;
                return _buildCallout(
                  context,
                  item: item,
                  index: i,
                  totalItems: flaskItems.length,
                  visualFill: visualFill,
                  flaskWidth: flaskWidth,
                  flaskHeight: flaskHeight,
                  onLeft: onLeft,
                );
              }),
            ],
          ),
        ),
        // ── Fill gauge text ────────────────────────────────────────────
        if (flaskItems.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${totalFlaskAmount.toStringAsFixed(1)}g / ${capacity.toStringAsFixed(0)}g'
            ' (${(fillRatio * 100).toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
          ),
        ],
        // ── Below-flask items (developer / treatment) ──────────────────
        if (belowItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: belowItems.map((d) {
              final c = Color(d.argbColor);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: c.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${d.source.product.code ?? d.label} '
                      '${d.amount.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: c.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCallout(
    BuildContext context, {
    required DropletItem item,
    required int index,
    required int totalItems,
    required double visualFill,
    required double flaskWidth,
    required double flaskHeight,
    required bool onLeft,
  }) {
    // Compute vertical position of the midpoint of this layer.
    // Layers stack bottom→top so we invert the position.
    final liquidHeight = flaskHeight * visualFill;
    // Layer proportional height.
    final layerH = item.amount /
        (items.where((d) => d.goesInFlask).fold(0.0, (s, d) => s + d.amount));
    // Midpoint from the bottom of liquid.
    double fromBottom = 0;
    for (var j = 0; j < index; j++) {
      final d = items.where((d) => d.goesInFlask).toList()[j];
      fromBottom +=
          d.amount /
          items.where((d) => d.goesInFlask).fold(0.0, (s, d2) => s + d2.amount);
    }
    fromBottom += layerH / 2;
    final yMid = flaskHeight - (liquidHeight * fromBottom);

    final c = Color(item.argbColor);
    final flaskLeft = 40.0;

    return Positioned(
      top: yMid - 14,
      left: onLeft ? 0 : flaskLeft + flaskWidth + 2,
      child: SizedBox(
        width: 38,
        child: Column(
          crossAxisAlignment: onLeft
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
            Text(
              '${item.amount.toStringAsFixed(1)}g',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            Text(
              item.source.product.code ?? item.label.split(' ').first,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Flask painter ────────────────────────────────────────────────────────────

class _FlaskPainter extends CustomPainter {
  final List<DropletItem> items;
  final double visualFill;
  final double totalAmount;

  const _FlaskPainter({
    required this.items,
    required this.visualFill,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Clip to flask shape ────────────────────────────────────────────
    final flaskPath = _buildFlaskPath(w, h);
    canvas.clipPath(flaskPath);

    // ── Background (empty flask) ───────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFF1F5F9),
    );

    if (items.isEmpty || totalAmount == 0) {
      _drawOutline(canvas, flaskPath);
      return;
    }

    // ── Liquid layers (bottom → top = first → last in list) ───────────
    final liquidH = h * visualFill;
    double cursor = h; // start from bottom

    for (final item in items) {
      final layerFrac = item.amount / totalAmount;
      final layerH = liquidH * layerFrac;
      final rect = Rect.fromLTWH(0, cursor - layerH, w, layerH);
      canvas.drawRect(rect, Paint()..color = Color(item.argbColor));
      cursor -= layerH;
    }

    // ── Semi-transparent meniscus gloss ───────────────────────────────
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.1, cursor - 4, w * 0.8, 10),
      glossPaint,
    );

    _drawOutline(canvas, flaskPath);
  }

  Path _buildFlaskPath(double w, double h) {
    // Erlenmeyer-ish flask: narrow neck on top, wider body at bottom
    final neckW = w * 0.38;
    final neckLeft = (w - neckW) / 2;
    final neckBottom = h * 0.35;

    final path = Path();
    path.moveTo(neckLeft, 0);
    path.lineTo(neckLeft + neckW, 0);
    path.lineTo(neckLeft + neckW, neckBottom);
    // Curve outward from neck to body
    path.cubicTo(
      neckLeft + neckW + (w - neckLeft - neckW) * 0.4,
      neckBottom + h * 0.15,
      w,
      h * 0.55,
      w,
      h * 0.78,
    );
    path.quadraticBezierTo(w, h, w * 0.5, h);
    path.quadraticBezierTo(0, h, 0, h * 0.78);
    path.cubicTo(
      0,
      h * 0.55,
      neckLeft - (w - neckLeft - neckW) * 0.4,
      neckBottom + h * 0.15,
      neckLeft,
      neckBottom,
    );
    path.close();
    return path;
  }

  void _drawOutline(Canvas canvas, Path path) {
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_FlaskPainter old) =>
      old.items != items ||
      old.visualFill != visualFill ||
      old.totalAmount != totalAmount;
}
