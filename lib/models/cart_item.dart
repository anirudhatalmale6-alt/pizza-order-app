class SelectedTopping {
  final String name;
  final String nameThai;
  final double price;

  SelectedTopping({
    required this.name,
    required this.nameThai,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'nameThai': nameThai, 'price': price,
  };

  factory SelectedTopping.fromJson(Map<String, dynamic> j) => SelectedTopping(
    name: j['name'] as String,
    nameThai: j['nameThai'] as String,
    price: (j['price'] as num).toDouble(),
  );
}

class CartItem {
  final String productName;
  final String productNameThai;
  final String productType;
  final double basePrice;
  int quantity;
  final List<SelectedTopping> toppings;

  CartItem({
    required this.productName,
    required this.productNameThai,
    required this.productType,
    required this.basePrice,
    this.quantity = 1,
    List<SelectedTopping>? toppings,
  }) : toppings = toppings ?? [];

  double get toppingsTotal => toppings.fold(0, (sum, t) => sum + t.price);
  double get itemTotal => (basePrice + toppingsTotal) * quantity;

  CartItem copyWith({List<SelectedTopping>? toppings}) {
    return CartItem(
      productName: productName,
      productNameThai: productNameThai,
      productType: productType,
      basePrice: basePrice,
      quantity: quantity,
      toppings: toppings ?? List.from(this.toppings.map((t) =>
        SelectedTopping(name: t.name, nameThai: t.nameThai, price: t.price))),
    );
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'productNameThai': productNameThai,
    'productType': productType,
    'basePrice': basePrice,
    'quantity': quantity,
    'toppings': toppings.map((t) => t.toJson()).toList(),
  };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    productName: j['productName'] as String,
    productNameThai: j['productNameThai'] as String,
    productType: j['productType'] as String,
    basePrice: (j['basePrice'] as num).toDouble(),
    quantity: j['quantity'] as int,
    toppings: (j['toppings'] as List)
        .map((t) => SelectedTopping.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}
