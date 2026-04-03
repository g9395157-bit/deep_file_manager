import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// Enum to define the type of confirmation (affects styling)
enum ConfirmationType {
  destructive, // red - for delete operations
  caution, // orange - for risky operations
  normal, // amber - for general confirmations
  info, // blue - for informational dialogs
}

/// A reusable confirmation card dialog that matches the app's design style.
/// 
/// Example:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (ctx) => ConfirmationCard(
///     title: 'Delete File',
///     message: 'Delete "document.pdf"? This cannot be undone.',
///     confirmText: 'Delete',
///     type: ConfirmationType.destructive,
///   ),
/// );
/// ```
class ConfirmationCard extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ConfirmationType type;
  final bool isDangerous;
  final IconData? icon;

  const ConfirmationCard({
    Key? key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.type = ConfirmationType.normal,
    this.isDangerous = false,
    this.icon,
  }) : super(key: key);

  Color get _accentColor {
    return switch (type) {
      ConfirmationType.destructive => kRed,
      ConfirmationType.caution => kOrange,
      ConfirmationType.normal => kAmber,
      ConfirmationType.info => kBlue,
    };
  }

  Color get _iconBgColor {
    return _accentColor.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon section
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: _accentColor,
                      size: 28,
                    ),
                  ),
                ),

              // ── Title
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  icon != null ? 16 : 24,
                  24,
                  0,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kBright,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // ── Message
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              // ── Divider
              Divider(
                height: 1,
                color: kBorder,
                indent: 0,
                endIndent: 0,
              ),

              // ── Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          onCancel?.call();
                          Navigator.of(context).pop(false);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          cancelText ?? 'Cancel',
                          style: TextStyle(
                            color: kMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Confirm button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onConfirm?.call();
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: kBg,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
