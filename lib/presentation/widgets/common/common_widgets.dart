import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ─── Agriculture background painter ──────────────────────────────────────────
class AgriBackground extends StatelessWidget {
  final Widget child;
  final bool overlay;
  const AgriBackground({super.key, required this.child, this.overlay = true});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB),
              Color(0xFFB8E4A0),
              Color(0xFF4A7C59),
              Color(0xFF2D6A4F),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
      ),
      CustomPaint(painter: _FieldPainter(), child: const SizedBox.expand()),
      if (overlay)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
      child,
    ]);
  }
}

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.38;

    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.25, h * 0.1), width: 90, height: 32),
        cloudPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.7, h * 0.16), width: 110, height: 36),
        cloudPaint);

    final sunPaint = Paint()
      ..color = const Color(0xFFFFF176).withOpacity(0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.82, h * 0.08), 22, sunPaint);

    final furrowPaint = Paint()
      ..color = const Color(0xFF1A3024).withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const numFurrows = 14;
    for (int i = 0; i <= numFurrows; i++) {
      final t = i / numFurrows;
      canvas.drawLine(
        Offset(w * 0.5, horizonY),
        Offset(w * t, h),
        furrowPaint,
      );
    }

    final cropPaint = Paint()
      ..color = const Color(0xFF52B788).withOpacity(0.45)
      ..style = PaintingStyle.fill;
    for (int row = 0; row < 5; row++) {
      final rowY = horizonY + (h - horizonY) * (row + 1) / 6;
      final spread = w * 0.04 * (row + 1);
      for (int col = 0; col <= 10; col++) {
        final cx = w * col / 10;
        final cy = rowY - 8 * (1 - row * 0.1);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, cy), width: spread * 0.6, height: 10),
          cropPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final bool isPaid;
  const StatusBadge({super.key, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.successSurface : AppColors.errorSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Pending',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPaid ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

// ─── Metric Card ─────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final Color? bgColor;
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppColors.primary;
    final bg = bgColor ?? AppColors.primarySurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 22),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: c, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}

// ─── TerraCard ────────────────────────────────────────────────────────────────
class TerraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  const TerraCard({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.inbox_outlined,
                size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
                textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Loading Overlay ─────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (isLoading)
        Container(
          color: Colors.black26,
          child: const Center(child: CircularProgressIndicator()),
        ),
    ]);
  }
}
