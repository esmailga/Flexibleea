import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/session.dart';
import '../../services/storage_service.dart';
import '../../services/user_repository.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/photo_picker.dart';
import 'auth_scaffold.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  File? _photo;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await pickProfilePhoto(context);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final users = context.read<UserRepository>();
    final storage = context.read<StorageService>();
    final session = context.read<Session>();
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    session.beginRegistration();
    try {
      final user = await auth.register(email: _email.text, password: _password.text);

      var imageUrl = '';
      var photoFailed = false;
      if (_photo != null) {
        try {
          imageUrl = await storage.uploadProfileImage(user.uid, _photo!);
        } catch (_) {
          photoFailed = true; // The account still works; the photo can be added later.
        }
      }

      await users.create(AppUser(
        id: user.uid,
        name: _name.text.trim(),
        email: user.email ?? _email.text.trim().toLowerCase(),
        phoneNumber: _phone.text.trim(),
        imageUrl: imageUrl,
      ));

      if (mounted && photoFailed) {
        showMessage(context, 'Account created, but the photo failed to upload. '
            'You can add it from your profile.', isError: true);
      }
      navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
      // If the auth account exists but the profile write failed, the
      // AuthGate shows the "complete your profile" screen instead.
      if (auth.currentUser != null) navigator.popUntil((route) => route.isFirst);
    } finally {
      session.endRegistration();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Join as a freelancer, a recruiter or both.',
      header: Column(
        children: [
          PhotoSlot(file: _photo, onTap: _loading ? () {} : _pickPhoto),
          const SizedBox(height: 12),
          Text(
            _photo == null ? 'Add a profile photo (optional)' : 'Looking good!',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  validator: Validators.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
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
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+60 12 345 6789',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm password',
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) =>
                      v?.trim() != _password.text.trim() ? 'Passwords do not match' : null,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        LoadingButton(
          label: 'Create account',
          icon: Icons.rocket_launch_rounded,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already a member?', style: theme.textTheme.bodyMedium),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
