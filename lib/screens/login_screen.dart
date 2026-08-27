import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleLogin() async {
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
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Auth backend isn't wired up yet; simulate the round trip for now.
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connexion bientôt disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            const _HeroHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    const Text(
                      'Content de vous revoir',
                      style: TextStyle(fontSize: 24, fontWeight: .w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Connectez-vous pour continuer',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    AuthTextField(
                      controller: _identifierController,
                      label: 'Email ou téléphone',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ce champ est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return '6 caractères minimum';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Se connecter',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou continuer avec', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SocialButton(label: _isGoogleLoading ? 'Connexion...' : 'Google', provider: SocialProvider.google, onPressed: _isGoogleLoading ? () {} : _handleGoogleLogin),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SocialButton(label: 'Apple', provider: SocialProvider.apple, onPressed: () {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/home');
                        },
                        child: const Text("Continuer en tant qu'invité"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: .center,
                      children: [
                        const Text('Pas encore de compte ?', style: TextStyle(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Créer un compte'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hohaya',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: .w600),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Trouvez votre\nprochain chez-vous',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: .w700, height: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            'Des milliers de logements vérifiés au Togo, à portée de main.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
