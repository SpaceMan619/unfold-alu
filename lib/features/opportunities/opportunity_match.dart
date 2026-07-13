import 'opportunity.dart';

/// One opportunity skill paired with whether the student already has it.
class SkillSignal {
  const SkillSignal({required this.skill, required this.have});

  final String skill;
  final bool have;
}

/// A deterministic, explainable fit score between a student's skills and an
/// [Opportunity]. No network call and no AI — it runs on the skills already
/// extracted onto the profile (see `cvAnalysisProvider`), so it works the same
/// for seeded and live Firestore data where `Opportunity.match` is unset.
///
/// The score is simply how much of the opportunity's required skill set the
/// student can already evidence. Being honest and legible beats being clever:
/// the same number that drives the ring also explains itself in [breakdown].
class OpportunityMatch {
  const OpportunityMatch({
    required this.score,
    required this.matched,
    required this.missing,
    required this.breakdown,
    required this.hasSignal,
  });

  factory OpportunityMatch.of(Opportunity opportunity, List<String> userSkills) {
    final userNorm = userSkills
        .map(_normalize)
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final breakdown = <SkillSignal>[];
    final matched = <String>[];
    final missing = <String>[];

    for (final skill in opportunity.skills) {
      final have = _userHas(skill, userNorm);
      breakdown.add(SkillSignal(skill: skill, have: have));
      (have ? matched : missing).add(skill);
    }

    final hasSignal = userNorm.isNotEmpty;
    final total = opportunity.skills.length;
    final score = (!hasSignal || total == 0)
        ? 0
        : ((matched.length / total) * 100).round();

    return OpportunityMatch(
      score: score,
      matched: matched,
      missing: missing,
      breakdown: breakdown,
      hasSignal: hasSignal,
    );
  }

  /// 0–100. Zero when we have no profile skills to compare against.
  final int score;

  /// Opportunity skills the student can already evidence.
  final List<String> matched;

  /// Opportunity skills the student does not yet have — the honest gap.
  final List<String> missing;

  /// Every opportunity skill in listed order, flagged have / not-have.
  final List<SkillSignal> breakdown;

  /// Whether the student had any skills on file to compare against.
  final bool hasSignal;

  /// A plain-language reason line, e.g. "Matches your Flutter and Firebase".
  String get whyLine {
    if (matched.isEmpty) return 'A stretch role to grow into';
    return 'Matches your ${_joinNaturally(matched)}';
  }
}

/// Opportunities adjacent to [current] by shared skills, best first, so a "no"
/// flows into the next option instead of a dead end. Ties break toward the
/// student's own better matches.
List<Opportunity> moreLikeThis(
  List<Opportunity> all,
  Opportunity current,
  List<String> userSkills, {
  int limit = 3,
}) {
  final currentSkills = current.skills.map(_normalize).toSet();

  int shared(Opportunity o) =>
      o.skills.map(_normalize).where(currentSkills.contains).length;

  final candidates = all.where((o) => o.id != current.id).toList()
    ..sort((a, b) {
      final bySkill = shared(b).compareTo(shared(a));
      if (bySkill != 0) return bySkill;
      final byFit = OpportunityMatch.of(b, userSkills)
          .score
          .compareTo(OpportunityMatch.of(a, userSkills).score);
      if (byFit != 0) return byFit;
      return a.role.compareTo(b.role);
    });

  return candidates.take(limit).toList();
}

String _normalize(String value) => value.trim().toLowerCase();

bool _userHas(String opportunitySkill, List<String> userNorm) {
  final target = _normalize(opportunitySkill);
  if (target.isEmpty) return false;
  for (final skill in userNorm) {
    if (skill == target) return true;
    if (skill.length >= 3 && target.contains(skill)) return true;
    if (target.length >= 3 && skill.contains(target)) return true;
  }
  return false;
}

String _joinNaturally(List<String> items) {
  if (items.length == 1) return items.first;
  if (items.length == 2) return '${items[0]} and ${items[1]}';
  final head = items.sublist(0, items.length - 1).join(', ');
  return '$head and ${items.last}';
}
