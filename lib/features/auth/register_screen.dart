import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _terms = true;
  bool _obscure = true;
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp _phoneRegex = RegExp(r'^[0-9]{10,}$');
  final RegExp _passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_terms) {
      messenger.showSnackBar(const SnackBar(content: Text('Accept Terms & Conditions.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _pass.text,
    );
    if (!mounted) return;
    if (ok) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.main, (_) => false);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(auth.error ?? 'Register failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          foreground: Paint()
            ..shader = AppColors.primaryGradient().createShader(const Rect.fromLTWH(0, 0, 260, 60)),
        );

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('SalonEase', style: titleStyle),
              const SizedBox(height: 10),
              Text('Create your account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 10))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(prefixIcon: Icon(IconlyLight.profile), hintText: 'Full name'),
                        validator: (v) => (v ?? '').trim().length >= 2 ? null : 'Enter your name',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(prefixIcon: Icon(IconlyLight.message), hintText: 'Email'),
                        validator: (v) => _emailRegex.hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(prefixIcon: Icon(IconlyLight.call), hintText: 'Phone'),
                        validator: (v) {
                          final phone = (v ?? '').trim();
                          if (!_phoneRegex.hasMatch(phone)) return 'Phone must be numeric and 10+ digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pass,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(IconlyLight.lock),
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? IconlyLight.show : IconlyLight.hide),
                          ),
                        ),
                        validator: (v) => _passwordRegex.hasMatch(v ?? '')
                            ? null
                            : 'Min 8 chars with at least 1 letter and 1 number',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        decoration: const InputDecoration(prefixIcon: Icon(IconlyLight.lock), hintText: 'Confirm password'),
                        validator: (v) => (v ?? '') == _pass.text ? null : 'Passwords do not match',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false)),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w700),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Terms link not configured.')),
                                        );
                                      },
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.w700),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Privacy link not configured.')),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      GradientButton(
                        expanded: true,
                        text: auth.isLoading ? 'Registering...' : 'Register',
                        onPressed: auth.isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: const Text('Already have account? Login', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

