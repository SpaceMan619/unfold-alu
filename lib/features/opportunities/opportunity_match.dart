import 'opportunity.dart';

class SkillSignal {
  const SkillSignal({required this.skill, required this.have});

  final String skill;
  final bool have;
}

// compares profile skills with the role's required skills
class OpportunityMatch {
  const OpportunityMatch({
    required this.score,
    required this.breakdown,
    required this.hasSignal,
  });

  factory OpportunityMatch.of(
    Opportunity opportunity,
    List<String> userSkills,
  ) {
    final userNorm = userSkills
        .map(_normalize)
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final breakdown = <SkillSignal>[];
    var matchedCount = 0;

    for (final skill in opportunity.skills) {
      final have = _userHas(skill, userNorm);
      breakdown.add(SkillSignal(skill: skill, have: have));
      if (have) matchedCount++;
    }

    final hasSignal = userNorm.isNotEmpty;
    final total = opportunity.skills.length;
    final score = (!hasSignal || total == 0)
        ? 0
        : ((matchedCount / total) * 100).round();

    return OpportunityMatch(
      score: score,
      breakdown: breakdown,
      hasSignal: hasSignal,
    );
  }

  final int score;
  final List<SkillSignal> breakdown;
  final bool hasSignal;
}

// ranks related roles once when the detail sheet opens
List<Opportunity> moreLikeThis(
  List<Opportunity> all,
  Opportunity current,
  List<String> userSkills, {
  int limit = 3,
}) {
  final currentSkills = current.skills.map(_normalize).toSet();
  final candidates = all.where((item) => item.id != current.id).toList();
  final sharedSkills = {
    for (final item in candidates)
      item.id: item.skills.map(_normalize).where(currentSkills.contains).length,
  };
  final scores = {
    for (final item in candidates)
      item.id: OpportunityMatch.of(item, userSkills).score,
  };
  candidates.sort((a, b) {
    final bySkill = sharedSkills[b.id]!.compareTo(sharedSkills[a.id]!);
    if (bySkill != 0) return bySkill;
    final byFit = scores[b.id]!.compareTo(scores[a.id]!);
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
