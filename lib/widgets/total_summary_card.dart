import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalSummaryCard extends StatelessWidget {
  final double totalMonthlyCost;
  final double totalAnnualCost;

  const TotalSummaryCard({
    super.key,
    required this.totalMonthlyCost,
    required this.totalAnnualCost,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'zh_TW',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(context, '月均支出', currencyFormat.format(totalMonthlyCost)),
          Container(width: 1, height: 50, color: Colors.white30),
          _buildItem(context, '年總支出', currencyFormat.format(totalAnnualCost)),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, String amount) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
