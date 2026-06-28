// lib/presentation/widgets/agri/agri_form_widgets.dart
//
// Shared building blocks for the agri module's CRUD screens (Lands,
// Workers, Work Entries, Expenses, Harvests): a labeled text field, a date
// picker row, a photo avatar/picker (camera + gallery, always returning
// Uint8List — Web-safe, matching AgriStorageService/new_entry_page.dart's
// established pattern of avoiding dart:io File), an error state, and a
// delete-confirmation dialog. Centralizing these avoids re-implementing the
// same boilerplate five times across the entity screens.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// A standard outlined text field used across all agri forms.
class AgriField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AgriField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: validator,
    );
  }
}

/// A read-only field that opens a date picker when tapped.
class AgriDateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AgriDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime(2015),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat('dd MMM yyyy').format(value)),
      ),
    );
  }
}

/// Opens a bottom sheet letting the user choose Camera or Gallery, then
/// returns the picked image as raw bytes. Returns null if the user
/// cancels at any step.
///
/// Always returns Uint8List (never a dart:io File) so this works
/// identically on Android, iOS, and Web — see AgriStorageService's header
/// comment for the full rationale.
Future<Uint8List?> pickAgriPhotoBytes(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: Text(l.takePhoto),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: Text(l.choosePhoto),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final xf = await ImagePicker().pickImage(source: source, imageQuality: 70);
  if (xf == null) return null;

  // readAsBytes() works across Android/iOS/Web; dart:io File does not exist
  // on Web, which is why this module never constructs a File.
  return xf.readAsBytes();
}

/// A circular photo picker showing newly-picked bytes, an existing network
/// photo, or a placeholder icon. Tapping it opens the camera/gallery sheet.
class AgriPhotoAvatar extends StatelessWidget {
  final Uint8List? newBytes;
  final String? networkUrl;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final double size;
  final IconData placeholderIcon;

  const AgriPhotoAvatar({
    super.key,
    required this.newBytes,
    required this.networkUrl,
    required this.onTap,
    this.onRemove,
    this.size = 84,
    this.placeholderIcon = Icons.add_a_photo_outlined,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (newBytes != null) {
      image = MemoryImage(newBytes!);
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      image = NetworkImage(networkUrl!);
    }
    final hasPhoto = image != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grey100,
              border: Border.all(color: AppColors.grey200, width: 1.5),
              image: hasPhoto
                  ? DecorationImage(image: image, fit: BoxFit.cover)
                  : null,
            ),
            child: !hasPhoto
                ? Icon(placeholderIcon, color: AppColors.grey500, size: size * 0.36)
                : null,
          ),
        ),
        if (hasPhoto && onRemove != null)
          Positioned(
            right: -4,
            top: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: AppColors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

/// Generic error state for a failed StreamProvider, shown in place of the
/// list when the underlying watchAll() stream emits an error.
class AgriErrorState extends StatelessWidget {
  final String message;
  const AgriErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(l.errorOccurred, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a Cancel/Delete confirmation dialog and resolves true only if the
/// user confirms deletion.
Future<bool> showAgriDeleteConfirm(BuildContext context, String message) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.confirmDelete),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(l.confirmDelete),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shows a transient snackbar for either a success message or a thrown
/// error object, used after form submissions across all agri screens.
void showAgriSnack(BuildContext context, {String? success, Object? error}) {
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: AppColors.error,
      ),
    );
  } else if (success != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
