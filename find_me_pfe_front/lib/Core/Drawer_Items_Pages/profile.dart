import 'package:find_me/ui/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';

/// Old entry point (drawer, settings icon). The page is now the unified
/// profile design and loads the signed-in user from the backend (/auth/me),
/// so [id] is kept only for compatibility with existing calls.
class MyProfile extends StatelessWidget {
  const MyProfile({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => const EditProfileScreen();
}
