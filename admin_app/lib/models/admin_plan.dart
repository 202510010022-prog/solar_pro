class AdminPlan {
  const AdminPlan({
    required this.slug,
    required this.name,
    required this.monthlyPrice,
  });

  final String slug;
  final String name;
  final double monthlyPrice;

  factory AdminPlan.fromMap(Map<String, dynamic> map) {
    final value = map['monthly_price'];
    return AdminPlan(
      slug: '${map['slug'] ?? ''}',
      name: '${map['name'] ?? ''}',
      monthlyPrice: value is num
          ? value.toDouble()
          : double.tryParse('$value') ?? 0,
    );
  }
}
