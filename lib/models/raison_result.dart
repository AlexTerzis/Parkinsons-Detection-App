class RaisonResult {
  const RaisonResult({
    required this.label,
    required this.explanation,
    required this.isSolution,
  });

  final String label;
  final List<String> explanation;
  final bool isSolution;

  factory RaisonResult.fromJson(Map<String, dynamic> json) {
    final option = json['option'] as Map<String, dynamic>? ?? {};
    return RaisonResult(
      label: option['label'] as String? ?? '',
      explanation: (json['explanation'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isSolution: json['isSolution'] as bool? ?? false,
    );
  }
}
