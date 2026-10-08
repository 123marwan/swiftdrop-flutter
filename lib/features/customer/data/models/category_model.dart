class CategoryModel {
  final int id;
  final String name;
  final String icon;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.color = '#FF6B35',
  });
}