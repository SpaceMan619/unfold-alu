import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum OpportunityType {
  internship('internship'),
  job('job'),
  volunteering('volunteering'),
  project('project');

  const OpportunityType(this.value);

  final String value;

  static OpportunityType fromValue(Object? value) {
    return OpportunityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OpportunityType.internship,
    );
  }
}

class Opportunity {
  const Opportunity({
    required this.id,
    required this.role,
    required this.startup,
    required this.summary,
    required this.location,
    required this.commitment,
    required this.skills,
    required this.color,
    this.ownerId = '',
    this.isPaid = false,
    this.monthlyAmount,
    this.currency = 'RWF',
    this.type = OpportunityType.internship,
    this.contactEmail = '',
    this.deadline,
  });

  final String id;
  final String role;
  final String startup;
  final String summary;
  final String location;
  final String commitment;
  final List<String> skills;
  final Color color;
  final String ownerId;
  final bool isPaid;
  final double? monthlyAmount;
  final String currency;
  final OpportunityType type;
  final String contactEmail;

  final DateTime? deadline;

  bool get isVolunteering => type == OpportunityType.volunteering;

  int? get daysUntilDeadline {
    final due = deadline;
    if (due == null) return null;
    final today = DateTime.now();
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  bool get isClosed {
    final days = daysUntilDeadline;
    return days != null && days < 0;
  }

  bool get closingSoon {
    final days = daysUntilDeadline;
    return days != null && days >= 0 && days <= 7;
  }

  String? get deadlineLabel {
    final days = daysUntilDeadline;
    if (days == null) return null;
    if (days < 0) return 'Closed';
    if (days == 0) return 'Closes today';
    if (days == 1) return 'Closes tomorrow';
    return 'Closes in $days days';
  }

  factory Opportunity.fromMap(String id, Map<String, dynamic> map) {
    return Opportunity(
      id: id,
      role: map['role'] as String? ?? '',
      startup: map['startupName'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      location: map['location'] as String? ?? 'Remote',
      commitment: map['commitment'] as String? ?? 'Flexible',
      skills: List<String>.from(map['skills'] as List? ?? const []),
      color: const Color(0xff68ddc9),
      ownerId: map['ownerId'] as String? ?? '',
      isPaid: map['isPaid'] as bool? ?? false,
      monthlyAmount: (map['monthlyAmount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'RWF',
      type: OpportunityType.fromValue(map['opportunityType']),
      contactEmail: map['contactEmail'] as String? ?? '',
      deadline: _readDeadline(map['deadline']),
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
      'opportunityType': type.value,
      'contactEmail': contactEmail,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
    };
  }
}

DateTime? _readDeadline(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
