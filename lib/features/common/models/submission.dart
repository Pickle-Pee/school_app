class Submission {
  Submission({
    required this.id,
    this.studentId,
    this.studentName,
    this.score,
    this.status,
  });

  final int id;
  final int? studentId;
  final String? studentName;
  final num? score;
  final String? status;

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      studentId: (json['student_id'] as num?)?.toInt(),
      studentName: json['student_name']?.toString() ??
          json['student']?.toString(),
      score: json['score'] as num?,
      status: json['status']?.toString(),
    );
  }
}
