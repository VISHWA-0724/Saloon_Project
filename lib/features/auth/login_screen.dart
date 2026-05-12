import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email: _email.text, password: _pass.text);
    if (!mounted) return;
    if (ok) {
      final route = auth.isAdmin ? AppRoutes.admin : AppRoutes.main;
      navigator.pushNamedAndRemoveUntil(route, (_) => false);
    } else {
      messenger
          .showSnackBar(SnackBar(content: Text(auth.error ?? 'Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          foreground: Paint()
            ..shader = AppColors.primaryGradient()
                .createShader(const Rect.fromLTWH(0, 0, 260, 60)),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text('SalonEase', style: titleStyle),
                const SizedBox(height: 10),
                Text(
                    'One login. Admins manage the shop, customers book services.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 16,
                          offset: Offset(0, 10))
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(IconlyLight.message),
                            hintText: 'Email',
                          ),
                          validator: (v) => Helpers.isValidEmail(v ?? '')
                              ? null
                              : 'Enter a valid email',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(IconlyLight.lock),
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? IconlyLight.show
                                  : IconlyLight.hide),
                            ),
                          ),
                          validator: (v) => (v ?? '').length >= 6
                              ? null
                              : 'Password must be at least 6 chars',
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please contact the salon admin to reset your password.')));
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GradientButton(
                          expanded: true,
                          text: auth.isLoading ? 'Logging in...' : 'Login',
                          onPressed: auth.isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.register),
                  child: const Text('New user? Create Account',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
