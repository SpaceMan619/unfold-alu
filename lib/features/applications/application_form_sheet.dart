import 'package:flutter/material.dart';

import '../../app/unfold_theme.dart';
import '../../core/widgets/glass_surface.dart';
import '../opportunities/opportunity.dart';

typedef ApplicationSubmit =
    Future<void> Function({
      required String motivation,
      required String availability,
      required String portfolioUrl,
    });

class ApplicationFormSheet extends StatefulWidget {
  const ApplicationFormSheet({
    required this.opportunity,
    required this.onSubmit,
    super.key,
  });

  final Opportunity opportunity;
  final ApplicationSubmit onSubmit;

  @override
  State<ApplicationFormSheet> createState() => _ApplicationFormSheetState();
}

class _ApplicationFormSheetState extends State<ApplicationFormSheet> {
  final formKey = GlobalKey<FormState>();
  final motivationController = TextEditingController();
  final portfolioController = TextEditingController();
  String availability = '';
  bool submitting = false;
  String? error;

  @override
  void dispose() {
    motivationController.dispose();
    portfolioController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      await widget.onSubmit(
        motivation: motivationController.text,
        availability: availability,
        portfolioUrl: portfolioController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        submitting = false;
        error = _message(exception);
      });
    }
  }

  String _message(Object exception) {
    final value = exception.toString().replaceFirst('Exception: ', '');
    return value.isEmpty ? 'We could not submit your application.' : value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 42),
      decoration: const BoxDecoration(
        color: Color(0xff10201d),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              28 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Your application',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Show the team why you are a strong fit.',
                style: TextStyle(color: UnfoldColors.muted),
              ),
              const SizedBox(height: 20),
              GlassSurface(
                radius: 22,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.opportunity.color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.work_outline_rounded,
                        color: UnfoldColors.ink,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.opportunity.role,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.opportunity.startup,
                            style: const TextStyle(color: UnfoldColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                key: const ValueKey('motivation-field'),
                controller: motivationController,
                minLines: 5,
                maxLines: 7,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: 'Why are you a good fit?',
                  hintText:
                      'Share a relevant project, strength, or reason you care about this work.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length == 0) {
                    return 'Tell the founder why you are interested.';
                  }
                  if (length < 60) {
                    return 'Add a little more detail (at least 60 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: const ValueKey('availability-field'),
                initialValue: availability.isEmpty ? null : availability,
                decoration: const InputDecoration(labelText: 'Availability'),
                items: const [
                  DropdownMenuItem(
                    value: 'Immediately',
                    child: Text('Immediately'),
                  ),
                  DropdownMenuItem(
                    value: 'Within 2 weeks',
                    child: Text('Within 2 weeks'),
                  ),
                  DropdownMenuItem(
                    value: 'Within 1 month',
                    child: Text('Within 1 month'),
                  ),
                  DropdownMenuItem(value: 'Flexible', child: Text('Flexible')),
                ],
                onChanged: submitting
                    ? null
                    : (value) => setState(() => availability = value ?? ''),
                validator: (value) => value == null || value.isEmpty
                    ? 'Choose when you can start.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('portfolio-field'),
                controller: portfolioController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Portfolio link (optional)',
                  hintText: 'https://github.com/your-name',
                ),
                validator: (value) {
                  final input = value?.trim() ?? '';
                  if (input.isEmpty) return null;
                  final uri = Uri.tryParse(input);
                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                    return 'Enter a complete link beginning with https://';
                  }
                  return null;
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                Text(
                  error!,
                  key: const ValueKey('submit-error'),
                  style: const TextStyle(color: Color(0xffff9b91)),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('submit-application'),
                onPressed: submitting ? null : submit,
                style: FilledButton.styleFrom(
                  backgroundColor: UnfoldColors.mint,
                  foregroundColor: UnfoldColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: UnfoldColors.ink,
                        ),
                      )
                    : const Text('Submit application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
