import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors `/itemCategories/{autoCategoryId}` (Section 9.2.C).
class CategoryModel {
  final String id;
  final String name;
  final String iconPath;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconPath = '',
  });

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return CategoryModel(
      id: doc.id,
      name: map['name'] as String? ?? 'General',
      iconPath: map['iconPath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'iconPath': iconPath};

  /// Seed list used as a fallback when the `itemCategories` collection is
  /// empty, so the form still works on a fresh database.
  static const List<CategoryModel> defaults = [
    CategoryModel(id: 'documents', name: 'Documents', iconPath: 'badge'),
    CategoryModel(id: 'electronics', name: 'Electronics', iconPath: 'devices'),
    CategoryModel(id: 'keys', name: 'Keys', iconPath: 'key'),
    CategoryModel(id: 'cash', name: 'Cash & Cards', iconPath: 'payments'),
    CategoryModel(id: 'bags', name: 'Bags', iconPath: 'backpack'),
    CategoryModel(id: 'others', name: 'Others', iconPath: 'category'),
  ];
}
