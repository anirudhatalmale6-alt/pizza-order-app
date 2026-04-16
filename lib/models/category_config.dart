class CategoryConfig {
  final String key;
  final String label;
  final String labelThai;
  final String icon;
  final String color;
  final double discount;
  final int sortOrder;
  final bool hasToppings;

  CategoryConfig({
    required this.key,
    required this.label,
    required this.labelThai,
    this.icon = 'restaurant',
    this.color = 'deepOrange',
    this.discount = 0,
    this.sortOrder = 0,
    this.hasToppings = false,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'labelThai': labelThai,
        'icon': icon,
        'color': color,
        'discount': discount,
        'sortOrder': sortOrder,
        'hasToppings': hasToppings,
      };

  factory CategoryConfig.fromJson(Map<String, dynamic> json) => CategoryConfig(
        key: json['key'] ?? '',
        label: json['label'] ?? '',
        labelThai: json['labelThai'] ?? '',
        icon: json['icon'] ?? 'restaurant',
        color: json['color'] ?? 'deepOrange',
        discount: (json['discount'] ?? 0).toDouble(),
        sortOrder: json['sortOrder'] ?? 0,
        hasToppings: json['hasToppings'] ?? false,
      );
}
