part of '../home_shell.dart';

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.onSwitch});
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final cv = ref.watch(cvAnalysisProvider);
    final photoBytes = ref.watch(profilePhotoBytesProvider).value;
    final publicProfile =
        ref.watch(publicProfileProvider).value ?? const PublicProfile();
    final initials = session.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 128),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: UnfoldColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: UnfoldColors.amber,
                  backgroundImage: photoBytes == null
                      ? null
                      : MemoryImage(photoBytes),
                  child: photoBytes == null
                      ? Text(
                          initials.isEmpty ? 'U' : initials,
                          style: const TextStyle(
                            color: UnfoldColors.ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final changed = await ref
                        .read(profilePhotoUploaderProvider)
                        .chooseAndUpload();
                    if (changed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile photo updated.')),
                      );
                    }
                  } on FormatException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Photo upload is unavailable right now.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(photoBytes == null ? 'Add photo' : 'Change photo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.name.isEmpty ? 'Unfold member' : session.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: UnfoldColors.cyan,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                session.email,
                style: const TextStyle(color: UnfoldColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 15),
              Text(
                publicProfile.bio.isEmpty
                    ? 'Add a short bio so founders understand what you care about.'
                    : publicProfile.bio,
                style: TextStyle(fontSize: 15, height: 1.45),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _ProfileMeta(
                    icon: Icons.location_on_outlined,
                    label: publicProfile.location,
                  ),
                  _ProfileMeta(
                    icon: Icons.school_outlined,
                    label: 'ALU · Class of ${publicProfile.classYear}',
                  ),
                  if (publicProfile.website.isNotEmpty)
                    _ProfileMeta(
                      icon: Icons.link_rounded,
                      label: publicProfile.website.replaceFirst(
                        RegExp(r'^https?://'),
                        '',
                      ),
                      onTap: () => _openExternalLink(publicProfile.website),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  _ProfileStat(value: '3', label: 'Projects'),
                  SizedBox(width: 24),
                  _ProfileStat(value: '2', label: 'Applications'),
                ],
              ),
              const SizedBox(height: 26),
              _SectionHeader(
                title: 'Profile details',
                action: 'Edit',
                onAction: () => _showSkillsEditor(context, ref, publicProfile),
              ),
              const SizedBox(height: 8),
              const Text(
                'Skills & interests',
                style: TextStyle(
                  color: UnfoldColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (publicProfile.skills.isNotEmpty ||
                  publicProfile.interests.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...publicProfile.skills.map(_SkillChip.new),
                    ...publicProfile.interests.map(
                      (interest) => _SkillChip(interest),
                    ),
                  ],
                )
              else if (cv.hasEvidence)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cv.skills.map(_SkillChip.new).toList(),
                )
              else
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SkillChip('Mobile products'),
                    _SkillChip('Community impact'),
                    _SkillChip('Open to internships'),
                  ],
                ),
              const SizedBox(height: 22),
              _CvIntelligenceCard(cv: cv),
              const SizedBox(height: 14),
              GlassSurface(
                child: const Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: UnfoldColors.mint),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'External profile preview',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'This is what verified founders see when reviewing you.',
                            style: TextStyle(
                              color: UnfoldColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onSwitch,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Switch to founder studio'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Unfold v0.8.0',
                  style: TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 11,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showSkillsEditor(
  BuildContext context,
  WidgetRef ref,
  PublicProfile profile,
) async {
  final skills = TextEditingController(text: profile.skills.join(', '));
  final interests = TextEditingController(text: profile.interests.join(', '));
  final bio = TextEditingController(text: profile.bio);
  final location = TextEditingController(text: profile.location);
  final website = TextEditingController(text: profile.website);
  var classYear = profile.classYear;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Container(
        padding: EdgeInsets.fromLTRB(
          22,
          18,
          22,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: UnfoldColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Skills & interests',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Separate each item with a comma.',
                style: TextStyle(color: UnfoldColors.muted),
              ),
              const SizedBox(height: 18),
              _OpportunityField(
                controller: bio,
                label: 'Bio',
                maxLines: 3,
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: location,
                label: 'Location',
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: classYear,
                decoration: const InputDecoration(
                  labelText: 'Class year',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var year = 2024; year <= 2032; year++)
                    DropdownMenuItem(
                      value: year,
                      child: Text('Class of $year'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => classYear = value);
                },
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: website,
                label: 'Website, GitHub, or portfolio',
                keyboardType: TextInputType.url,
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: skills,
                label: 'Skills',
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: interests,
                label: 'Interests',
                validator: (_) => null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    List<String> parse(String value) => value
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .take(8)
                        .toList();
                    await ref
                        .read(publicProfileEditorProvider)
                        .save(
                          skills: parse(skills.text),
                          interests: parse(interests.text),
                          bio: bio.text,
                          location: location.text,
                          classYear: classYear,
                          website: website.text,
                        );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  skills.dispose();
  interests.dispose();
  bio.dispose();
  location.dispose();
  website.dispose();
}

class _ProfileMeta extends StatelessWidget {
  const _ProfileMeta({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: UnfoldColors.muted),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: UnfoldColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

Future<void> _openExternalLink(String value) async {
  final normalized = value.startsWith('http') ? value : 'https://$value';
  final uri = Uri.tryParse(normalized);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(color: UnfoldColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _CvIntelligenceCard extends ConsumerWidget {
  const _CvIntelligenceCard({required this.cv});

  final CvAnalysisState cv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassSurface(
      color: UnfoldColors.cyan.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.document_scanner_rounded,
                color: UnfoldColors.cyan,
              ),
              const SizedBox(width: 10),
              const Text(
                'CV intelligence',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      (cv.hasEvidence ? UnfoldColors.mint : UnfoldColors.amber)
                          .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  cv.hasEvidence ? 'AI INTEGRATED' : 'AI READY',
                  style: TextStyle(
                    color: cv.hasEvidence
                        ? UnfoldColors.mint
                        : UnfoldColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cv.stage == CvAnalysisStage.selected ||
                    cv.stage == CvAnalysisStage.analyzing
                ? cv.fileName ?? 'CV selected'
                : cv.stage == CvAnalysisStage.ready
                ? cv.summary
                : 'Upload your CV to build an editable skills profile and unlock explainable matches.',
            style: const TextStyle(color: UnfoldColors.muted),
          ),
          const SizedBox(height: 16),
          if (cv.stage == CvAnalysisStage.selected)
            Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: UnfoldColors.mint,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'PDF ready for private analysis',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(cvAnalysisProvider.notifier).removeCv(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(cvAnalysisProvider.notifier).analyze(),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Analyze CV with AI'),
                  ),
                ),
              ],
            )
          else if (cv.stage == CvAnalysisStage.analyzing)
            const Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Reading your CV…'),
              ],
            )
          else if (cv.stage == CvAnalysisStage.ready)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cv.skills
                      .map(
                        (skill) => InputChip(
                          label: Text(skill),
                          onDeleted: () => ref
                              .read(cvAnalysisProvider.notifier)
                              .removeSkill(skill),
                          deleteIcon: const Icon(Icons.close_rounded, size: 15),
                        ),
                      )
                      .toList(),
                ),
                if (cv.suggestedRoles.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Suggested: ${cv.suggestedRoles.join(' · ')}',
                    style: const TextStyle(color: UnfoldColors.cyan),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(cvAnalysisProvider.notifier).selectCv(),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload updated CV'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove CV intelligence',
                      onPressed: () =>
                          ref.read(cvAnalysisProvider.notifier).removeCv(),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            )
          else if (cv.stage == CvAnalysisStage.failed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cv.error ?? 'Analysis failed.',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            ref.read(cvAnalysisProvider.notifier).analyze(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry analysis'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(cvAnalysisProvider.notifier).selectCv(),
                      child: const Text('New PDF'),
                    ),
                  ],
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(cvAnalysisProvider.notifier).selectCv(),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Choose PDF CV'),
              ),
            ),
        ],
      ),
    );
  }
}
