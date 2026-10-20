import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../services/session.dart';
import '../../services/storage_service.dart';
import '../../services/user_repository.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/photo_picker.dart';

/// Edits the signed-in member's profile. Without [existing] it acts as the
/// "complete your profile" step for accounts that have no profile document.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.existing});

  final AppUser? existing;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phoneNumber ?? '');
  File? _photo;
  bool _saving = false;

  bool get _isCompleting => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await pickProfilePhoto(context);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<Session>();
    final users = context.read<UserRepository>();
    final storage = context.read<StorageService>();
    final navigator = Navigator.of(context);
    final user = session.user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      var imageUrl = widget.existing?.imageUrl ?? '';
      if (_photo != null) {
        imageUrl = await storage.uploadProfileImage(user.uid, _photo!);
      }
      if (_isCompleting) {
        await users.create(AppUser(
          id: user.uid,
          name: _name.text.trim(),
          email: user.email ?? '',
          phoneNumber: _phone.text.trim(),
          imageUrl: imageUrl,
        ));
      } else {
        await users.update(widget.existing!.copyWith(
          name: _name.text.trim(),
          phoneNumber: _phone.text.trim(),
          imageUrl: imageUrl,
        ));
        if (mounted) showMessage(context, 'Profile updated');
        navigator.pop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.read<Session>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCompleting ? 'Complete your profile' : 'Edit profile'),
        automaticallyImplyLeading: !_isCompleting,
        actions: [
          if (_isCompleting)
            TextButton(onPressed: session.signOut, child: const Text('Sign out')),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isCompleting)
                  Text(
                    'Tell people who you are. This is shown on your listings and reviews.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 24),
                Center(
                  child: PhotoSlot(
                    file: _photo,
                    imageUrl: widget.existing?.imageUrl ?? '',
                    onTap: _saving ? () {} : _pickPhoto,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _name,
                  validator: Validators.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+60 12 345 6789',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                LoadingButton(
                  label: _isCompleting ? 'Continue' : 'Save changes',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _save,
                ),
              ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ),
      ),
    );
  }
}
