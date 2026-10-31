import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Reusable upload card supporting empty dropzone state and selected file preview.
class FileUploadCard extends StatelessWidget {
  const FileUploadCard({
    required this.title,
    required this.subtitle,
    required this.capacityNote,
    required this.icon,
    required this.actions,
    this.selectedFileName,
    this.selectedFileBytes,
    this.isImage = false,
    this.onRemove,
    this.onChange,
    this.loading = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String capacityNote;
  final IconData icon;
  final Widget actions;
  final String? selectedFileName;
  final Uint8List? selectedFileBytes;
  final bool isImage;
  final VoidCallback? onRemove;
  final VoidCallback? onChange;
  final bool loading;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primaryTeal = isDark ? AppColors.darkPrimary : AppColors.primary;

    if (selectedFileName != null && selectedFileBytes != null) {
      // Selected File Preview State
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: primaryTeal.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.memory(
                    selectedFileBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 84,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF142C38) : const Color(0xFFEFFBFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, size: 40, color: primaryTeal),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: primaryTeal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        _formatFileSize(selectedFileBytes!.length),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!loading) ...[
                  IconButton(
                    onPressed: onChange,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Change file',
                    color: primaryTeal,
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Remove file',
                    color: Colors.redAccent,
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    // Empty Dropzone State
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Icon Badge
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF133644) : const Color(0xFFE0F7FA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isDark ? const Color(0xFF65D4D8) : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: subtitleColor,
              height: 1.4,
            ),
          ),
          if (capacityNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              capacityNote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
          const SizedBox(height: 18),
          actions,
        ],
      ),
    );
  }
}

/// A compact, tactile outline action button used inside upload cards (e.g. "Take a Photo >", "Choose from Gallery >").
class CardActionButton extends StatelessWidget {
  const CardActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTeal = isDark ? AppColors.darkPrimary : AppColors.primary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashFactory: InkRipple.splashFactory,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor ?? primaryTeal),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
