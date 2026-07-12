import 'package:flutter/material.dart';

class Opportunity {
  const Opportunity({
    required this.id,
    required this.role,
    required this.startup,
    required this.summary,
    required this.location,
    required this.commitment,
    required this.skills,
    required this.match,
    required this.color,
    this.ownerId = '',
    this.isPaid = false,
    this.monthlyAmount,
    this.currency = 'RWF',
  });

  final String id;
  final String role;
  final String startup;
  final String summary;
  final String location;
  final String commitment;
  final List<String> skills;
  final int match;
  final Color color;
  final String ownerId;
  final bool isPaid;
  final double? monthlyAmount;
  final String currency;

  factory Opportunity.fromMap(String id, Map<String, dynamic> map) {
    return Opportunity(
      id: id,
      role: map['role'] as String? ?? '',
      startup: map['startupName'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      location: map['location'] as String? ?? 'Remote',
      commitment: map['commitment'] as String? ?? 'Flexible',
      skills: List<String>.from(map['skills'] as List? ?? const []),
      match: 0,
      color: const Color(0xff68ddc9),
      ownerId: map['ownerId'] as String? ?? '',
      isPaid: map['isPaid'] as bool? ?? false,
      monthlyAmount: (map['monthlyAmount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'RWF',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'startupName': startup,
      'summary': summary,
      'location': location,
      'commitment': commitment,
      'skills': skills,
      'status': 'active',
      'isPaid': isPaid,
      'monthlyAmount': monthlyAmount,
      'currency': currency,
    };
  }
}

const demoOpportunities = [
  Opportunity(
    id: 'mobile-dev',
    role: 'Mobile developer intern',
    startup: 'Soma Labs',
    summary:
        'Help shape a learning companion built for low-bandwidth classrooms.',
    location: 'Kigali · Hybrid',
    commitment: '12 hrs / week',
    skills: ['Flutter', 'Firebase', 'Product'],
    match: 92,
    color: Color(0xff68ddc9),
  ),
  Opportunity(
    id: 'growth',
    role: 'Growth & community fellow',
    startup: 'Kijani Works',
    summary:
        'Tell the stories behind a circular design community across campus.',
    location: 'Remote',
    commitment: '8 hrs / week',
    skills: ['Research', 'Content', 'Community'],
    match: 84,
    color: Color(0xffffc66b),
  ),
  Opportunity(
    id: 'analyst',
    role: 'Venture operations analyst',
    startup: 'Nuru Mobility',
    summary:
        'Turn early pilot data into decisions for a cleaner Kigali commute.',
    location: 'Kigali · On-site',
    commitment: '10 hrs / week',
    skills: ['Analytics', 'Operations', 'Strategy'],
    match: 78,
    color: Color(0xff9fa8ff),
  ),
];
