import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/common_widgets.dart';
import '../../core/theme/app_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AgriBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.agriculture,
                    color: AppColors.white, size: 48),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text('TerraTrack',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text('Land Work Management',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.white.withOpacity(0.8)))
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2)
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
