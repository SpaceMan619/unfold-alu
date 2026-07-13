part of '../home_shell.dart';

class _CreateOpportunitySheet extends StatefulWidget {
  const _CreateOpportunitySheet({required this.onCreate, this.initial});

  final Future<void> Function(Opportunity) onCreate;
  final Opportunity? initial;

  @override
  State<_CreateOpportunitySheet> createState() =>
      _CreateOpportunitySheetState();
}

class _CreateOpportunitySheetState extends State<_CreateOpportunitySheet> {
  final formKey = GlobalKey<FormState>();
  final startupController = TextEditingController();
  final roleController = TextEditingController();
  final summaryController = TextEditingController();
  final skillsController = TextEditingController();
  final amountController = TextEditingController();
  final contactEmailController = TextEditingController();
  String arrangement = 'Hybrid';
  bool isPaid = false;
  String currency = 'RWF';
  OpportunityType opportunityType = OpportunityType.internship;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      startupController.text = initial.startup;
      roleController.text = initial.role;
      summaryController.text = initial.summary;
      skillsController.text = initial.skills.join(', ');
      isPaid = initial.isPaid;
      currency = initial.currency;
      amountController.text = initial.monthlyAmount?.toStringAsFixed(0) ?? '';
      contactEmailController.text = initial.contactEmail;
      opportunityType = initial.type;
    }
  }

  @override
  void dispose() {
    startupController.dispose();
    roleController.dispose();
    summaryController.dispose();
    skillsController.dispose();
    amountController.dispose();
    contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 56),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff10201d),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
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
              const SizedBox(height: 24),
              Text(
                'Create opportunity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Be specific about the work and what the student will learn.',
                style: TextStyle(color: UnfoldColors.muted),
              ),
              const SizedBox(height: 22),
              _OpportunityField(
                controller: startupController,
                label: 'Startup or venture name',
                validator: _required,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: roleController,
                label: 'Role title',
                validator: _required,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: summaryController,
                label: 'What will they work on?',
                maxLines: 3,
                validator: _required,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: skillsController,
                label: 'Skills, separated by commas',
                validator: _required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<OpportunityType>(
                initialValue: opportunityType,
                decoration: const InputDecoration(
                  labelText: 'Opportunity type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in OpportunityType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.value[0].toUpperCase() + type.value.substring(1),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => opportunityType = value);
                },
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: contactEmailController,
                label: 'Contact email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  return email.isNotEmpty && !email.contains('@')
                      ? 'Enter a valid email'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Paid opportunity'),
                subtitle: Text(
                  isPaid
                      ? 'Add the monthly stipend below.'
                      : 'This role is unpaid.',
                  style: const TextStyle(color: UnfoldColors.muted),
                ),
                value: isPaid,
                activeTrackColor: UnfoldColors.mint,
                onChanged: (value) => setState(() => isPaid = value),
              ),
              if (isPaid) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OpportunityField(
                        controller: amountController,
                        label: 'Monthly amount',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (!isPaid) return null;
                          final amount = double.tryParse(value ?? '');
                          return amount == null || amount <= 0
                              ? 'Enter a valid amount'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'RWF', label: Text('RWF')),
                        ButtonSegment(value: 'USD', label: Text('USD')),
                      ],
                      selected: {currency},
                      onSelectionChanged: (value) =>
                          setState(() => currency = value.first),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Remote', label: Text('Remote')),
                  ButtonSegment(value: 'Hybrid', label: Text('Hybrid')),
                  ButtonSegment(value: 'On-site', label: Text('On-site')),
                ],
                selected: {arrangement},
                onSelectionChanged: (selection) {
                  setState(() => arrangement = selection.first);
                },
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const ValueKey('publish-opportunity'),
                onPressed: submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: UnfoldColors.mint,
                  foregroundColor: UnfoldColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: Text(submitting ? 'Publishing…' : 'Publish opportunity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    final skills = skillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .take(5)
        .toList();
    setState(() => submitting = true);
    await widget.onCreate(
      Opportunity(
        id:
            widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        role: roleController.text.trim(),
        startup: startupController.text.trim(),
        summary: summaryController.text.trim(),
        location: 'Kigali · $arrangement',
        commitment: 'Flexible',
        skills: skills,
        match: 80,
        color: UnfoldColors.cyan,
        ownerId: widget.initial?.ownerId ?? '',
        isPaid: isPaid,
        monthlyAmount: isPaid ? double.parse(amountController.text) : null,
        currency: currency,
        type: opportunityType,
        contactEmail: contactEmailController.text.trim(),
      ),
    );
    if (mounted) setState(() => submitting = false);
  }
}

class _OpportunityField extends StatelessWidget {
  const _OpportunityField({
    required this.controller,
    required this.label,
    required this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}
