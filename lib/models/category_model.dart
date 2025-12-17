import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static List<CategoryModel> defaultCategories() {
    return [
      CategoryModel(
        id: 'ent',
        name: '娛樂',
        icon: Icons.movie_creation_outlined,
        color: const Color(0xffeb6f92),
      ),
      CategoryModel(
        id: 'prod',
        name: '生產力',
        icon: Icons.work_outline,
        color: const Color(0xff31748f),
      ),
      CategoryModel(
        id: 'util',
        name: '工具',
        icon: Icons.build_circle_outlined,
        color: const Color(0xff9ccfd8),
      ),
      CategoryModel(
        id: 'life',
        name: '生活',
        icon: Icons.coffee_outlined,
        color: const Color(0xfff6c177),
      ),
      CategoryModel(
        id: 'music',
        name: '音樂',
        icon: Icons.music_note_outlined,
        color: const Color(0xffc4a7e7),
      ),
      CategoryModel(
        id: 'other',
        name: '其他',
        icon: Icons.grid_view,
        color: Colors.grey,
      ),
    ];
  }
}
