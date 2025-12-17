import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class SubscriptionFormScreen extends StatefulWidget {
  final Subscription? initialSubscription;
  final List<CategoryModel> categories;

  const SubscriptionFormScreen({
    super.key,
    this.initialSubscription,
    required this.categories,
  });

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _noteController;
  late BillingCycle _selectedCycle;
  late DateTime _selectedStartDate;
  late String _selectedCurrency;
  late String _selectedCategoryId;

  // [新增] 通知設定變數
  late int _remindDaysBefore;

  final List<String> _currencies = ['TWD', 'USD', 'JPY', 'EUR', 'CNY'];

  // [新增] 通知選項
  final Map<int, String> _reminderOptions = {
    -1: '不通知',
    0: '付款當天',
    1: '提早 1 天',
    3: '提早 3 天',
    7: '提早 1 週',
  };

  bool get isEditing => widget.initialSubscription != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSubscription;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _costController = TextEditingController(
      text: initial?.cost.toString() ?? '',
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _selectedCycle = initial?.cycle ?? BillingCycle.monthly;
    _selectedStartDate = initial?.startDate ?? DateTime.now();
    _selectedCurrency = initial?.currency ?? 'TWD';
    _remindDaysBefore = initial?.remindDaysBefore ?? -1;

    if (initial != null &&
        widget.categories.any((c) => c.id == initial.categoryId)) {
      _selectedCategoryId = initial.categoryId;
    } else {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final subscription = Subscription(
        id: isEditing
            ? widget.initialSubscription!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        cost: double.parse(_costController.text),
        currency: _selectedCurrency,
        cycle: _selectedCycle,
        startDate: _selectedStartDate,
        categoryId: _selectedCategoryId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        remindDaysBefore: _remindDaysBefore, // 儲存通知設定
      );
      Navigator.pop(context, subscription);
    }
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) setState(() => _selectedStartDate = pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '編輯訂閱' : '新增訂閱'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('基本資訊'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '訂閱名稱',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => v!.isEmpty ? '請輸入名稱' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: '分類',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 18, color: cat.color),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v!),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('費用與週期'),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '金額',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) =>
                          (double.tryParse(v ?? '') ?? 0) <= 0 ? '無效金額' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: '幣別',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _currencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<BillingCycle>(
                      value: _selectedCycle,
                      decoration: const InputDecoration(
                        labelText: '繳費週期',
                        prefixIcon: Icon(Icons.update),
                      ),
                      items: BillingCycle.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCycle = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('日期與提醒'),
              InkWell(
                onTap: _presentDatePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '首次付款日期',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'yyyy/MM/dd',
                                ).format(_selectedStartDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Text(
                        '變更',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // [新增] 通知設定下拉選單
              DropdownButtonFormField<int>(
                value: _remindDaysBefore,
                decoration: const InputDecoration(
                  labelText: '付款提醒',
                  prefixIcon: Icon(Icons.notifications_outlined),
                ),
                items: _reminderOptions.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _remindDaysBefore = v!),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('備註 (選填)'),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: '例如：透過信用卡付款、家庭方案...',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? '儲存變更' : '新增訂閱',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
