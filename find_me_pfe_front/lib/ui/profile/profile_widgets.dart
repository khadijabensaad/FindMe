import 'dart:typed_data';

import 'package:find_me/Auth/login.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared building blocks of every profile-related page (My Profile mockup).

/// Clears the session on this device and returns to the login page.
Future<void> logoutUser(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userToken');
  await prefs.remove('stylistSession');
  await prefs.remove('manualLocation');
  await prefs.setBool('activated', false);
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(CupertinoPageRoute(builder: (_) => const LoginPage()), (_) => false);
}

Future<void> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.card,
      title: Text('Log out?', style: AppTheme.display(20, color: ctx.fg)),
      content: const Text('You will need your email and password to sign in again.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out', style: TextStyle(color: Color(0xFFA8321F)))),
      ],
    ),
  );
  if (ok == true && context.mounted) await logoutUser(context);
}

/// Centred page title with optional back and trailing action.
class ProfileHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showBack;
  const ProfileHeader(this.title, {super.key, this.trailing, this.showBack = true});
  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    return Row(children: [
      SizedBox(
        width: 48,
        child: canPop ? IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.fg), onPressed: () => Navigator.pop(context)) : null,
      ),
      Expanded(child: Text(title, textAlign: TextAlign.center, style: AppTheme.display(22, color: context.fg))),
      SizedBox(width: 48, child: trailing),
    ]);
  }
}

/// Circular avatar inside the caramel frame. Shows [bytes] (new photo) first,
/// then the network [image], then the default avatar asset.
class ProfileAvatar extends StatelessWidget {
  final String image;
  final Uint8List? bytes;
  final double size;
  final VoidCallback? onEdit;
  const ProfileAvatar({super.key, required this.image, this.bytes, this.size = 128, this.onEdit});
  @override
  Widget build(BuildContext context) {
    final Widget pic = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover)
        : image.isEmpty
            ? Image.asset('assets/images/avatar.png', fit: BoxFit.cover)
            : AppNetworkImage(image);
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        padding: EdgeInsets.all(size * 0.04),
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.caramel, boxShadow: AppColors.softShadow),
        child: Container(
          padding: EdgeInsets.all(size * 0.03),
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.bg),
          child: ClipOval(child: SizedBox(width: size, height: size, child: pic)),
        ),
      ),
      if (onEdit != null)
        Positioned(
          right: 4,
          bottom: 4,
          child: Material(
            color: AppColors.ink,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(padding: EdgeInsets.all(9), child: Icon(Icons.photo_camera_rounded, color: AppColors.cream, size: 18)),
            ),
          ),
        )
      else
        const Positioned(right: 2, bottom: 10, child: Icon(Icons.auto_awesome, color: AppColors.camel, size: 22)),
    ]);
  }
}

/// "Username:" / "Email:" rows with the caramel label.
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const ProfileInfoRow(this.icon, this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: context.isDark ? AppColors.camel : AppColors.brown, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$label:', style: context.text.labelMedium?.copyWith(color: context.accentText)),
            const SizedBox(height: 2),
            Text(value.isEmpty ? '—' : value, style: context.text.bodyLarge),
          ]),
        ),
      ]),
    );
  }
}

/// List entry used on profile pages.
class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const ProfileTile(this.icon, this.label, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: context.line)),
          leading: Icon(icon, color: context.isDark ? AppColors.camel : AppColors.brown),
          title: Text(label, style: context.text.titleSmall),
          trailing: Icon(Icons.chevron_right_rounded, color: context.fgMuted),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Caramel pill button (LOG OUT, SAVE…).
class CaramelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final double width;
  const CaramelButton(this.label, {super.key, this.onTap, this.busy = false, this.width = 200});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: onTap == null && !busy ? 0.5 : 1,
        child: Material(
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            decoration: BoxDecoration(gradient: AppColors.caramel, borderRadius: BorderRadius.circular(30), boxShadow: AppColors.softShadow),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: busy ? null : onTap,
              child: SizedBox(
                width: width,
                height: 52,
                child: Center(
                  child: busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                      : Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.ink)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
