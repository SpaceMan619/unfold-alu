import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/opportunities/opportunity.dart';

void main() {
  test('volunteering and contact details survive map conversion', () {
    const opportunity = Opportunity(
      id: 'volunteer-role',
      role: 'Community volunteer',
      startup: 'Prototype venture',
      summary: 'Support a community event.',
      location: 'Kigali',
      commitment: '4 hrs / week',
      skills: ['Teamwork'],
      match: 80,
      color: Color(0xff68ddc9),
      type: OpportunityType.volunteering,
      contactEmail: 'volunteer@example.com',
    );

    final restored = Opportunity.fromMap(opportunity.id, opportunity.toMap());

    expect(restored.type, OpportunityType.volunteering);
    expect(restored.isVolunteering, isTrue);
    expect(restored.contactEmail, 'volunteer@example.com');
  });

  test('older records default to internship with no contact email', () {
    final restored = Opportunity.fromMap('legacy', {
      'role': 'Legacy role',
      'startupName': 'Legacy venture',
    });

    expect(restored.type, OpportunityType.internship);
    expect(restored.contactEmail, isEmpty);
    expect(restored.isVolunteering, isFalse);
  });
}
