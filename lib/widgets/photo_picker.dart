import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_theme.dart';
import 'feedback.dart';

/// Lets the user take or choose a photo, then crops it to a square.
/// Returns null if the user cancels at any step.
Future<File?> pickProfilePhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profile photo',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              label: 'Take a photo',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return null;

  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      maxWidth: 1080,
      maxHeight: 1080,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: AppColors.brand,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.brand,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    return cropped == null ? null : File(cropped.path);
  } catch (e) {
    if (context.mounted) {
      showMessage(context, 'Could not open the photo. Check app permissions.',
          isError: true);
    }
    return null;
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        leading: Icon(icon, color: scheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

/// Tappable circular photo slot used on sign-up and profile editing.
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({
    super.key,
    required this.onTap,
    this.file,
    this.imageUrl = '',
    this.size = 112,
  });

  final VoidCallback onTap;
  final File? file;
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ImageProvider? image;
    if (file != null) {
      image = FileImage(file!);
    } else if (imageUrl.isNotEmpty) {
      image = NetworkImage(imageUrl);
    }

    return Semantics(
      button: true,
      label: 'Choose profile photo',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: image == null ? AppColors.heroGradient : null,
                image: image == null
                    ? null
                    : DecorationImage(image: image, fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: image == null
                  ? Icon(Icons.person_rounded, size: size * 0.5, color: Colors.white)
                  : null,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 3),
                ),
                child: Icon(Icons.photo_camera_rounded, size: 18, color: scheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
