import 'dart:typed_data';

import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/profile/profile_widgets.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Account settings in the My Profile design. Everything is saved in the backend
/// (PUT /auth/updateProfile, PUT /auth/changePassword); nothing is hard-coded.
class EditProfileScreen extends StatefulWidget {
  /// Optional: shown instantly while /auth/me reloads the fresh data.
  final AppUser? user;
  const EditProfileScreen({super.key, this.user});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _api = FindMeApi.instance;
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  AppUser? _user;
  Uint8List? _photo;
  String _photoName = 'profile.jpg';
  bool _saving = false;
  bool _changing = false;
  bool _hide = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setUser(widget.user);
    _reload();
  }

  void _setUser(AppUser? u) {
    _user = u;
    if (u != null) _name.text = u.username;
  }

  Future<void> _reload() async {
    try {
      final u = await _api.me();
      if (mounted) setState(() => _setUser(u));
    } catch (e) {
      if (mounted && _user == null) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 900, imageQuality: 85);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      _photo = b;
      _photoName = x.name.isEmpty ? 'profile.jpg' : x.name;
    });
  }

  bool get _dirty => _photo != null || (_user != null && _name.text.trim() != _user!.username);

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      _toast('The username must have at least 2 characters.');
      return;
    }
    setState(() => _saving = true);
    try {
      final u = await _api.updateProfile(
        username: name != _user?.username ? name : null,
        photoBytes: _photo,
        photoName: _photoName,
      );
      if (!mounted) return;
      setState(() {
        _setUser(u);
        _photo = null;
      });
      _toast('Profile updated ✨');
    } catch (e) {
      if (mounted) _toast('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_current.text.isEmpty || _next.text.isEmpty) {
      _toast('Fill in your current and new password.');
      return;
    }
    if (_next.text.length < 8) {
      _toast('The new password must have at least 8 characters.');
      return;
    }
    if (_next.text != _confirm.text) {
      _toast('The two new passwords are different.');
      return;
    }
    setState(() => _changing = true);
    try {
      await _api.changePassword(_current.text, _next.text);
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _confirm.clear();
      _toast('Password changed.');
    } catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    return Scaffold(
      body: SafeArea(
        child: u == null
            ? (_error != null
                ? Column(children: [const ProfileHeader('Edit Profile'), Expanded(child: ErrorRetry(message: _error!, onRetry: _reload))])
                : const Center(child: CircularProgressIndicator(color: AppColors.camel)))
            : ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 40), children: [
                const ProfileHeader('Edit Profile'),
                const SizedBox(height: 18),
                Center(child: ProfileAvatar(image: u.image, bytes: _photo, onEdit: _pickPhoto)),
                const SizedBox(height: 8),
                Center(child: TextButton(onPressed: _pickPhoto, child: Text('Change photo', style: TextStyle(color: context.accentText)))),
                const SizedBox(height: 10),
                _label('Username'),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: 14),
                ProfileInfoRow(Icons.mail_rounded, 'Email', u.email),
                const SizedBox(height: 18),
                CaramelButton('SAVE', busy: _saving, onTap: _dirty ? _save : null, width: double.infinity),
                const SizedBox(height: 30),
                Text('Change password', style: AppTheme.display(19, color: context.fg)),
                const SizedBox(height: 10),
                _password(_current, 'Current password'),
                _password(_next, 'New password (8+ characters)'),
                _password(_confirm, 'Confirm new password'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _changing ? null : _changePassword,
                    icon: _changing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.camel))
                        : const Icon(Icons.lock_reset_rounded),
                    label: const Text('Update password'),
                  ),
                ),
                const SizedBox(height: 34),
                CaramelButton('LOG OUT', onTap: () => confirmLogout(context)),
              ]),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text('$t:', style: context.text.labelMedium?.copyWith(color: context.accentText)),
      );

  Widget _password(TextEditingController c, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          obscureText: _hide,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _hide = !_hide)),
          ),
        ),
      );
}
