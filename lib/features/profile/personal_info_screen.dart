import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/widgets/gradient_button.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name.text = u?.name ?? '';
    _phone.text = u?.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null || !mounted) return;
    final ok = await context.read<AuthProvider>().uploadProfileImage(img.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Profile photo updated' : 'Failed to upload photo')),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().updateProfile(
          name: _name.text,
          phone: _phone.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save profile')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Center(
            child: Stack(
              children: [
                Hero(
                  tag: 'user_avatar',
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage: CachedNetworkImageProvider(
                      u?.profileImage ?? 'https://source.unsplash.com/200x200/?portrait',
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _pickAndUpload,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'Full name'),
                  validator: (v) => (v ?? '').trim().length >= 2 ? null : 'Enter a valid name',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Phone number'),
                  validator: (v) {
                    final phone = (v ?? '').trim();
                    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) return 'Phone must be numeric';
                    if (phone.length < 10) return 'Phone must be at least 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GradientButton(
                  expanded: true,
                  text: auth.isLoading ? 'Saving...' : 'Save Changes',
                  onPressed: auth.isLoading ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
