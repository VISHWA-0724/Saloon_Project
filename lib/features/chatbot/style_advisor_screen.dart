import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../data/services/style_advisor_service.dart';

class StyleAdvisorScreen extends StatefulWidget {
  const StyleAdvisorScreen({super.key});

  @override
  State<StyleAdvisorScreen> createState() => _StyleAdvisorScreenState();
}

class _StyleAdvisorScreenState extends State<StyleAdvisorScreen> {
  final _advisor = StyleAdvisorService();
  final _messages = <_AdvisorMessage>[];
  final _input = TextEditingController();
  final _age = TextEditingController();
  final _scroll = ScrollController();

  String? _gender;
  String? _hairType;
  String? _faceShape;
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    final welcome = _advisor.welcome();
    _messages.add(
      _AdvisorMessage(
        text: welcome.text,
        fromUser: false,
        summary: welcome.detectedSummary,
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _age.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    if (_thinking) return;

    final typed = (preset ?? _input.text).trim();
    final structured = _structuredPrompt();
    if (typed.isEmpty && structured.isEmpty) return;

    final userText = typed.isEmpty ? structured : typed;
    final age = int.tryParse(_age.text.trim());
    final gender = _gender;
    final hairType = _hairType;
    final faceShape = _faceShape;

    setState(() {
      _messages.add(_AdvisorMessage(text: userText, fromUser: true));
      _thinking = true;
      _input.clear();
    });
    _scrollToBottom();

    StyleAdvice advice;
    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService.create(
        token: auth.token,
        onUnauthorized: auth.logout,
      );
      final data = await api.post('/api/ai/style-advisor', data: {
        'prompt': userText,
        'age': age,
        'gender': gender,
        'hairType': hairType,
        'faceShape': faceShape,
      }) as Map<String, dynamic>;
      final source = data['source']?.toString() == 'huggingface'
          ? 'Live Hugging Face'
          : 'Local fallback';
      final summary = (data['detectedSummary'] ?? 'Style advice').toString();
      advice = StyleAdvice(
        text: (data['text'] ?? '').toString(),
        detectedSummary: '$source | $summary',
      );
    } catch (_) {
      advice = _advisor.recommend(
        userText,
        age: age,
        gender: gender,
        hairType: hairType,
        faceShape: faceShape,
      );
    }

    if (!mounted) return;
    setState(() {
      _messages.add(
        _AdvisorMessage(
          text: advice.text,
          fromUser: false,
          summary: advice.detectedSummary,
        ),
      );
      _thinking = false;
    });
    _scrollToBottom();
  }

  String _structuredPrompt() {
    final parts = <String>[
      if (_age.text.trim().isNotEmpty) 'Age ${_age.text.trim()}',
      if (_gender != null) _title(_gender!),
      if (_hairType != null) '${_title(_hairType!)} hair',
      if (_faceShape != null) '${_title(_faceShape!)} face',
    ];
    return parts.join(', ');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _title(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient(),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Style Advisor',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Haircuts, beard shapes, and salon services',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                children: [
                  _AdvisorProfileCard(
                    age: _age,
                    gender: _gender,
                    hairType: _hairType,
                    faceShape: _faceShape,
                    onGenderChanged: (value) => setState(() => _gender = value),
                    onHairTypeChanged: (value) =>
                        setState(() => _hairType = value),
                    onFaceShapeChanged: (value) =>
                        setState(() => _faceShape = value),
                    onSuggest: () => _send(),
                  ),
                  const SizedBox(height: 12),
                  _QuickPrompts(onSelected: _send),
                  const SizedBox(height: 12),
                  ..._messages
                      .map((message) => _MessageBubble(message: message)),
                  if (_thinking) const _TypingBubble(),
                ],
              ),
            ),
            _Composer(
              controller: _input,
              enabled: !_thinking,
              onSubmitted: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisorProfileCard extends StatelessWidget {
  final TextEditingController age;
  final String? gender;
  final String? hairType;
  final String? faceShape;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onHairTypeChanged;
  final ValueChanged<String?> onFaceShapeChanged;
  final VoidCallback onSuggest;

  const _AdvisorProfileCard({
    required this.age,
    required this.gender,
    required this.hairType,
    required this.faceShape,
    required this.onGenderChanged,
    required this.onHairTypeChanged,
    required this.onFaceShapeChanged,
    required this.onSuggest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 8))
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 660
              ? 4
              : constraints.maxWidth >= 430
                  ? 2
                  : 1;
          final spacing = 10.0 * (columns - 1);
          final fieldWidth = (constraints.maxWidth - spacing) / columns;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Style Profile',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _AdvisorDropdown(
                      value: gender,
                      label: 'Gender',
                      icon: IconlyLight.profile,
                      items: const {
                        'male': 'Male',
                        'female': 'Female',
                      },
                      onChanged: onGenderChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _AdvisorDropdown(
                      value: hairType,
                      label: 'Hair Type',
                      icon: Icons.waves_rounded,
                      items: const {
                        'straight': 'Straight',
                        'wavy': 'Wavy',
                        'curly': 'Curly',
                        'coily': 'Coily',
                        'thick': 'Thick',
                        'thin': 'Thin',
                        'dry': 'Dry',
                        'oily': 'Oily',
                      },
                      onChanged: onHairTypeChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _AdvisorDropdown(
                      value: faceShape,
                      label: 'Face Shape',
                      icon: Icons.face_retouching_natural_outlined,
                      items: const {
                        'round': 'Round',
                        'oval': 'Oval',
                        'square': 'Square',
                        'heart': 'Heart',
                        'diamond': 'Diamond',
                        'long': 'Long',
                      },
                      onChanged: onFaceShapeChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSuggest,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Suggest Styles',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    minimumSize: const Size(double.infinity, 48),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdvisorDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _AdvisorDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _QuickPrompts({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const prompts = [
      '24 male oval face wavy hair',
      '30 female round face straight hair',
      '38 male square face thick hair',
      'Curly hair with long face',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prompts
          .map(
            (prompt) => ActionChip(
              label: Text(prompt),
              avatar: const Icon(Icons.bolt_rounded, size: 16),
              onPressed: () => onSelected(prompt),
              side: const BorderSide(color: AppColors.border),
              backgroundColor: Theme.of(context).cardColor,
            ),
          )
          .toList(),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _AdvisorMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    final background =
        isUser ? AppColors.primaryPurple : Theme.of(context).cardColor;
    final foreground = isUser ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.summary != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.primaryPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    message.summary!,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.primaryPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Chip(
          avatar: SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text('Checking styles...'),
          side: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 16, offset: Offset(0, -8))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmitted,
              decoration: const InputDecoration(
                hintText: 'Ask for a style recommendation...',
                prefixIcon: Icon(IconlyLight.message),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed:
                enabled ? () => onSubmitted(controller.text.trim()) : null,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              minimumSize: const Size(52, 52),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))),
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _AdvisorMessage {
  final String text;
  final bool fromUser;
  final String? summary;

  const _AdvisorMessage({
    required this.text,
    required this.fromUser,
    this.summary,
  });
}
