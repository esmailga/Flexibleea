import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/expertise_listing.dart';

/// The official Saudi Riyal sign, introduced by the Saudi Central Bank (SAMA)
/// in 2025. Its Unicode code point (U+20C1) is too new for most fonts, so the
/// glyph is drawn from SAMA's published SVG artwork, normalised to height 1.
class RiyalSymbol extends StatelessWidget {
  const RiyalSymbol({super.key, this.height = 14, this.color});

  /// Width / height of the official artwork (viewBox 1124.14 x 1256.39).
  static const aspectRatio = 0.89474;

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ??
        DefaultTextStyle.of(context).style.color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return CustomPaint(
      size: Size(height * aspectRatio, height),
      painter: _RiyalPainter(resolved),
    );
  }
}

class _RiyalPainter extends CustomPainter {
  _RiyalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.height);
    canvas.drawPath(_riyalPath, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RiyalPainter oldDelegate) => oldDelegate.color != color;
}

/// A price such as "⃁ 220/hr": the riyal sign sits on the text baseline at
/// numeral height, before the amount, scaled to whatever [style] is in effect.
class RiyalAmount extends StatelessWidget {
  const RiyalAmount({
    super.key,
    required this.amount,
    this.style,
    this.suffix = '/hr',
  });

  final double amount;
  final TextStyle? style;
  final String suffix;

  /// Height of the sign relative to font size: SAMA's guidance is to match
  /// the numerals, which are ~0.76em tall in Plus Jakarta Sans.
  static const signHeight = 0.76;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final fontSize = effective.fontSize ?? 14;
    final value = formatAmount(amount);
    final spoken = '$value Saudi riyals${suffix == '/hr' ? ' per hour' : ''}';

    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: effective,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: EdgeInsets.only(right: fontSize * 0.22),
                child: RiyalSymbol(height: fontSize * signHeight, color: effective.color),
              ),
            ),
            TextSpan(text: value),
            if (suffix.isNotEmpty)
              TextSpan(
                text: suffix,
                style: TextStyle(
                  fontSize: fontSize * 0.78,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Shows a listing's hourly rate with the riyal sign, falling back to the
/// free-text rate stored by older versions of the app.
class RateText extends StatelessWidget {
  const RateText({super.key, required this.listing, this.style, this.placeholder = '—'});

  final ExpertiseListing listing;
  final TextStyle? style;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final rate = listing.hourlyRate;
    if (rate != null) return RiyalAmount(amount: rate, style: style);
    final legacy = listing.legacyRate;
    return Text(
      legacy.isEmpty ? placeholder : legacy,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

final Path _riyalPath = Path()
  // Lower bar
  ..moveTo(0.55685, 0.88589)
  ..cubicTo(0.54088, 0.92129, 0.53033, 0.95971, 0.52629, 1.00000)
  ..lineTo(0.86417, 0.92818)
  ..cubicTo(0.88013, 0.89278, 0.89068, 0.85435, 0.89473, 0.81406)
  ..lineTo(0.55685, 0.88589)
  ..close()
  // Main letterform
  ..moveTo(0.86417, 0.71300)
  ..cubicTo(0.88013, 0.67760, 0.89069, 0.63917, 0.89473, 0.59888)
  ..lineTo(0.63153, 0.65486)
  ..lineTo(0.63153, 0.54725)
  ..lineTo(0.86416, 0.49782)
  ..cubicTo(0.88012, 0.46242, 0.89068, 0.42399, 0.89472, 0.38370)
  ..lineTo(0.63152, 0.43963)
  ..lineTo(0.63152, 0.05263)
  ..cubicTo(0.59119, 0.07528, 0.55538, 0.10542, 0.52626, 0.14098)
  ..lineTo(0.52626, 0.46201)
  ..lineTo(0.42100, 0.48439)
  ..lineTo(0.42100, 0.00000)
  ..cubicTo(0.38067, 0.02264, 0.34485, 0.05279, 0.31574, 0.08834)
  ..lineTo(0.31574, 0.50675)
  ..lineTo(0.08021, 0.55680)
  ..cubicTo(0.06425, 0.59220, 0.05369, 0.63062, 0.04963, 0.67091)
  ..lineTo(0.31574, 0.61436)
  ..lineTo(0.31574, 0.74988)
  ..lineTo(0.03056, 0.81048)
  ..cubicTo(0.01459, 0.84588, 0.00404, 0.88430, 0.00000, 0.92459)
  ..lineTo(0.29850, 0.86116)
  ..cubicTo(0.32280, 0.85610, 0.34368, 0.84174, 0.35726, 0.82197)
  ..lineTo(0.41201, 0.74081)
  ..cubicTo(0.41769, 0.73239, 0.42100, 0.72227, 0.42100, 0.71136)
  ..lineTo(0.42100, 0.59199)
  ..lineTo(0.52626, 0.56962)
  ..lineTo(0.52626, 0.78484)
  ..lineTo(0.86416, 0.71298)
  ..close();
