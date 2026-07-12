import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { submitted, reviewing, shortlisted, accepted, rejected }

class OpportunityApplication {
  const OpportunityApplication({
    required this.id,
    required this.opportunityId,
    required this.studentId,
    this.founderId = '',
    required this.motivation,
    this.availability = '',
    this.portfolioUrl = '',
    required this.status,
    required this.createdAt,
    this.studentName = 'ALU student',
    this.studentEmail = '',
    this.roleTitle = 'Opportunity applicant',
    this.skills = const [],
    this.location = 'ALU community',
  });

  final String id;
  final String opportunityId;
  final String studentId;
  final String founderId;
  final String motivation;
  final String availability;
  final String portfolioUrl;
  final ApplicationStatus status;
  final DateTime createdAt;
  final String studentName;
  final String studentEmail;
  final String roleTitle;
  final List<String> skills;
  final String location;

  OpportunityApplication copyWith({ApplicationStatus? status}) {
    return OpportunityApplication(
      id: id,
      opportunityId: opportunityId,
      studentId: studentId,
      founderId: founderId,
      motivation: motivation,
      availability: availability,
      portfolioUrl: portfolioUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      studentName: studentName,
      studentEmail: studentEmail,
      roleTitle: roleTitle,
      skills: skills,
      location: location,
    );
  }

  factory OpportunityApplication.fromMap(String id, Map<String, dynamic> map) {
    return OpportunityApplication(
      id: id,
      opportunityId: map['opportunityId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      founderId: map['founderId'] as String? ?? '',
      motivation: map['motivation'] as String? ?? '',
      availability: map['availability'] as String? ?? '',
      portfolioUrl: map['portfolioUrl'] as String? ?? '',
      status: ApplicationStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ApplicationStatus.submitted,
      ),
      createdAt: _readDate(map['createdAt']),
      studentName: map['studentName'] as String? ?? 'ALU student',
      studentEmail: map['studentEmail'] as String? ?? '',
      roleTitle: map['roleTitle'] as String? ?? 'Opportunity applicant',
      skills: List<String>.from(map['skills'] as List? ?? const []),
      location: map['location'] as String? ?? 'ALU community',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opportunityId': opportunityId,
      'studentId': studentId,
      'founderId': founderId,
      'motivation': motivation,
      'availability': availability,
      'portfolioUrl': portfolioUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'studentName': studentName,
      'studentEmail': studentEmail,
      'roleTitle': roleTitle,
      'skills': skills,
      'location': location,
    };
  }
}

DateTime _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
