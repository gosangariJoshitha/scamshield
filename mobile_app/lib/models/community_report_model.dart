class CommunityReportModel {
  const CommunityReportModel({
    required this.id,
    required this.content,
    required this.category,
    this.description,
    this.evidence,
    this.analysisId,
    required this.reporterName,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String content;
  final String category;
  final String? description;
  final String? evidence;
  final int? analysisId;
  final String reporterName;
  final String status;
  final DateTime createdAt;

  factory CommunityReportModel.fromJson(Map<String, dynamic> json) {
    return CommunityReportModel(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String?,
      evidence: json['evidence'] as String?,
      analysisId: json['analysis_id'] as int?,
      reporterName: json['reporter_name'] as String? ?? 'Community member',
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
