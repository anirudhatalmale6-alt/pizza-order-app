class SelectedTopping {
  final String name;
  final String nameThai;
  final double price;

  SelectedTopping({
    required this.name,
    required this.nameThai,
    required this.price,
  });
}

class CartItem {
  final String productName;
  final String productNameThai;
  final String productType; // 'pizza' or 'drink'
  final double basePrice;
  final String optionGroup; // links to toppings/options group
  int quantity;
  final List<SelectedTopping> toppings;

  CartItem({
    required this.productName,
    required this.productNameThai,
    required this.productType,
    required this.basePrice,
    this.optionGroup = '',
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
      optionGroup: optionGroup,
      quantity: quantity,
      toppings: toppings ?? List.from(this.toppings.map((t) =>
        SelectedTopping(name: t.name, nameThai: t.nameThai, price: t.price))),
    );
  }
}
