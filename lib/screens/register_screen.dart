import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_button.dart';

enum UserRole { locataire, proprietaire }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  UserRole _role = UserRole.locataire;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleRegister() async {
    setState(() => _isGoogleLoading = true);
    try {
      await AuthService().signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on GoogleAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google n’est pas configuré sur cet appareil.')));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez accepter les conditions d'utilisation")),
      );
      return;
    }

    // Auth backend isn't wired up yet; simulate the round trip for now.
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inscription bientôt disponible')),
    );
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const Text(
                'Rejoignez Hohaya',
                style: TextStyle(fontSize: 24, fontWeight: .w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Créez votre compte en quelques secondes',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      label: 'Locataire',
                      description: 'Je cherche un logement',
                      icon: Icons.person_search_outlined,
                      selected: _role == UserRole.locataire,
                      onTap: () => setState(() => _role = UserRole.locataire),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      label: 'Propriétaire',
                      description: 'Je loue un logement',
                      icon: Icons.apartment_outlined,
                      selected: _role == UserRole.proprietaire,
                      onTap: () => setState(() => _role = UserRole.proprietaire),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: _nameController,
                label: 'Nom complet',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
                  final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                  if (!emailRegex.hasMatch(value.trim())) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _phoneController,
                label: 'Téléphone (+228...)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().length < 8) return 'Numéro invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Mot de passe',
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: .start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text.rich(
                        TextSpan(
                          text: "J'accepte les ",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: "conditions d'utilisation",
                              style: TextStyle(color: AppColors.primary, fontWeight: .w600),
                            ),
                            const TextSpan(text: ' et la '),
                            TextSpan(
                              text: 'politique de confidentialité',
                              style: TextStyle(color: AppColors.primary, fontWeight: .w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Créer mon compte',
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("ou s'inscrire avec", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: SocialButton(label: _isGoogleLoading ? 'Inscription...' : 'Google', provider: SocialProvider.google, onPressed: _isGoogleLoading ? () {} : _handleGoogleRegister)),
                  const SizedBox(width: 12),
                  Expanded(child: SocialButton(label: 'Apple', provider: SocialProvider.apple, onPressed: () {})),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: .center,
                children: [
                  const Text('Déjà un compte ?', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontWeight: .w600, color: selected ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
