enum DeviceStatus {
  empty, // 空き
  using, // 使用中
  beforeUsing, // 使用前（予約済み）
  warning // 切り忘れ
}

// 状態の説明
extension DeviceStatusExtension on DeviceStatus {
  String get name {
    switch (this) {
      case DeviceStatus.empty:
        return '空き';
      case DeviceStatus.using:
        return '使用中';
      case DeviceStatus.beforeUsing:
        return '使用前';
      case DeviceStatus.warning:
        return '切り忘れ';
      default:
        return '';
    }
  }
}
