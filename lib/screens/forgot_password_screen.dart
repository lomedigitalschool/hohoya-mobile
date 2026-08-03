import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { requestCode, resetPassword }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.requestCode;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _step = _Step.resetPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Un code a été envoyé à ${_emailController.text.trim()}')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé, vous pouvez vous connecter')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == _Step.requestCode ? _buildRequestCodeStep() : _buildResetPasswordStep(),
        ),
      ),
    );
  }

  Widget _buildRequestCodeStep() {
    return Column(
      key: const ValueKey(_Step.requestCode),
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Mot de passe oublié',
          style: TextStyle(fontSize: 24, fontWeight: .w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Entrez votre email, nous vous enverrons un code de vérification',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        Form(
          key: _emailFormKey,
          child: AuthTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Ce champ est requis';
              final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
              if (!emailRegex.hasMatch(trimmed)) return 'Email invalide';
              return null;
            },
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Envoyer le code',
          isLoading: _isLoading,
          onPressed: _handleSendCode,
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    return Column(
      key: const ValueKey(_Step.resetPassword),
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Vérification du code',
          style: TextStyle(fontSize: 24, fontWeight: .w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Entrez le code reçu par email et votre nouveau mot de passe',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        Form(
          key: _resetFormKey,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              AuthTextField(
                controller: _codeController,
                label: 'Code de vérification',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Nouveau mot de passe',
                icon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.length < 6) return '6 caractères minimum';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmController,
                label: 'Confirmer le mot de passe',
                icon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Réinitialiser le mot de passe',
          isLoading: _isLoading,
          onPressed: _handleResetPassword,
        ),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () => setState(() => _step = _Step.requestCode),
            child: const Text('Changer d\'email'),
          ),
        ),
      ],
    );
  }
}
