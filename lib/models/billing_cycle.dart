enum BillingCycle { monthly, annually }

extension BillingCycleExtension on BillingCycle {
  String get displayName {
    switch (this) {
      case BillingCycle.monthly:
        return '月繳';
      case BillingCycle.annually:
        return '年繳';
    }
  }
}
