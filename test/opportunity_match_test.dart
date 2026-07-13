import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/opportunities/opportunity.dart';
import 'package:unfold/features/opportunities/opportunity_match.dart';

Opportunity _opp({
  String id = 'o1',
  String role = 'Flutter product intern',
  String summary = 'Shape mobile product ideas for small-business finance.',
  List<String> skills = const ['Flutter', 'Firebase', 'UI testing'],
}) {
  return Opportunity(
    id: id,
    role: role,
    startup: 'Kayko',
    summary: summary,
    location: 'Kigali · Hybrid',
    commitment: '12 hrs / week',
    skills: skills,
    match: 0,
    color: const Color(0xff68ddc9),
  );
}

void main() {
  group('OpportunityMatch.of', () {
    test('no user skills means no signal, score stays zero', () {
      final match = OpportunityMatch.of(_opp(), const []);
      expect(match.hasSignal, isFalse);
      expect(match.score, 0);
      expect(match.matched, isEmpty);
    });

    test('full coverage scores 100 and lists every skill as matched', () {
      final match = OpportunityMatch.of(
        _opp(),
        const ['Flutter', 'Firebase', 'UI testing'],
      );
      expect(match.hasSignal, isTrue);
      expect(match.score, 100);
      expect(match.missing, isEmpty);
      expect(match.matched.length, 3);
    });

    test('partial coverage lands between 0 and 100 with the gap surfaced', () {
      final match = OpportunityMatch.of(_opp(), const ['Flutter', 'Firebase']);
      expect(match.score, greaterThan(40));
      expect(match.score, lessThan(100));
      expect(match.matched, containsAll(<String>['Flutter', 'Firebase']));
      expect(match.missing, contains('UI testing'));
    });

    test('matching is case and whitespace insensitive', () {
      final match = OpportunityMatch.of(_opp(), const ['  flutter ', 'FIREBASE']);
      expect(match.matched, containsAll(<String>['Flutter', 'Firebase']));
    });

    test('related phrasing still counts (contains either direction)', () {
      final match = OpportunityMatch.of(
        _opp(skills: const ['Flutter']),
        const ['Flutter development'],
      );
      expect(match.matched, contains('Flutter'));
    });

    test('breakdown preserves opportunity skill order with have flags', () {
      final match = OpportunityMatch.of(_opp(), const ['Firebase']);
      expect(match.breakdown.map((e) => e.skill).toList(),
          <String>['Flutter', 'Firebase', 'UI testing']);
      expect(match.breakdown[1].have, isTrue);
      expect(match.breakdown[0].have, isFalse);
    });

    test('whyLine names matched skills in plain language', () {
      final match = OpportunityMatch.of(_opp(), const ['Flutter', 'Firebase']);
      expect(match.whyLine, 'Matches your Flutter and Firebase');
    });

    test('whyLine handles a single match', () {
      final match = OpportunityMatch.of(_opp(), const ['Firebase']);
      expect(match.whyLine, 'Matches your Firebase');
    });
  });

  group('moreLikeThis', () {
    final all = [
      _opp(id: 'current', skills: const ['Flutter', 'Firebase', 'UI testing']),
      _opp(id: 'near', skills: const ['Flutter', 'REST APIs', 'Maps']),
      _opp(id: 'far', skills: const ['Field research', 'Operations']),
      _opp(id: 'near2', skills: const ['Firebase', 'Python']),
    ];

    test('excludes the current opportunity', () {
      final result = moreLikeThis(all, all.first, const []);
      expect(result.any((o) => o.id == 'current'), isFalse);
    });

    test('ranks skill-adjacent opportunities ahead of unrelated ones', () {
      final result = moreLikeThis(all, all.first, const [], limit: 3);
      expect(result.first.id, anyOf('near', 'near2'));
      expect(result.last.id, 'far');
    });

    test('respects the limit', () {
      final result = moreLikeThis(all, all.first, const [], limit: 2);
      expect(result.length, 2);
    });
  });
}
