import 'package:flutter/material.dart';
import '../models/models.dart';

class CategoryManagementScreen extends StatefulWidget {
  final List<CategoryModel> currentCategories;

  const CategoryManagementScreen({super.key, required this.currentCategories});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late List<CategoryModel> _categories;

  final List<IconData> _availableIcons = [
    Icons.movie,
    Icons.music_note,
    Icons.games,
    Icons.tv,
    Icons.headset,
    Icons.book,
    Icons.newspaper,
    Icons.palette,
    Icons.camera_alt,
    Icons.image,
    Icons.home,
    Icons.shopping_cart,
    Icons.local_dining,
    Icons.coffee,
    Icons.local_bar,
    Icons.chair,
    Icons.bed,
    Icons.lightbulb,
    Icons.pets,
    Icons.child_care,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.directions_bike,
    Icons.train,
    Icons.flight,
    Icons.local_gas_station,
    Icons.map,
    Icons.hotel,
    Icons.phone_android,
    Icons.computer,
    Icons.wifi,
    Icons.cloud,
    Icons.security,
    Icons.email,
    Icons.chat,
    Icons.smart_toy,
    Icons.work,
    Icons.school,
    Icons.edit,
    Icons.folder,
    Icons.calendar_today,
    Icons.attach_money,
    Icons.account_balance,
    Icons.credit_card,
    Icons.fitness_center,
    Icons.pool,
    Icons.spa,
    Icons.local_hospital,
    Icons.medication,
    Icons.build,
    Icons.settings,
    Icons.cleaning_services,
    Icons.local_laundry_service,
    Icons.checkroom,
    Icons.content_cut,
    Icons.card_giftcard,
    Icons.favorite,
    Icons.star,
    Icons.bolt,
    Icons.category,
    Icons.grid_view,
  ];

  final List<Color> _availableColors = [
    const Color(0xffeb6f92),
    const Color(0xffebbcba),
    const Color(0xfff6c177),
    const Color(0xffebcb8b),
    const Color(0xffa3be8c),
    const Color(0xff31748f),
    const Color(0xff9ccfd8),
    const Color(0xffc4a7e7),
    Colors.brown,
    Colors.grey,
    const Color(0xff26233a),
    Colors.redAccent,
    Colors.blueAccent,
  ];

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.currentCategories);
  }

  void _onBack() {
    Navigator.pop(context, _categories);
  }

  void _showAddEditDialog({CategoryModel? existingCategory}) {
    final isEditing = existingCategory != null;
    final nameController = TextEditingController(
      text: existingCategory?.name ?? '',
    );
    IconData selectedIcon = existingCategory?.icon ?? _availableIcons[0];
    Color selectedColor = existingCategory?.color ?? _availableColors[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? '編輯分類' : '新增分類'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '分類名稱',
                          hintText: '例如：交通...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '標籤顏色',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableColors.map((color) {
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = color),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '選擇圖示',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _availableIcons.length,
                            itemBuilder: (ctx, index) {
                              final icon = _availableIcons[index];
                              final isSelected = selectedIcon == icon;
                              return GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedIcon = icon),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 24,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    this.setState(() {
                      if (isEditing) {
                        final index = _categories.indexWhere(
                          (c) => c.id == existingCategory.id,
                        );
                        if (index != -1) {
                          _categories[index] = CategoryModel(
                            id: existingCategory.id,
                            name: nameController.text.trim(),
                            icon: selectedIcon,
                            color: selectedColor,
                          );
                        }
                      } else {
                        _categories.add(
                          CategoryModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: nameController.text.trim(),
                            icon: selectedIcon,
                            color: selectedColor,
                          ),
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('分類管理'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBack,
          ),
          actions: [
            TextButton(
              onPressed: _onBack,
              child: const Text(
                '完成',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isDeletable = cat.id != 'other';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat.icon, color: cat.color),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showAddEditDialog(existingCategory: cat),
                    ),
                    if (isDeletable)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('刪除分類'),
                              content: Text('確定要刪除「${cat.name}」嗎？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _categories.removeAt(index);
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text(
                                    '刪除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(),
          label: const Text('新增分類'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
