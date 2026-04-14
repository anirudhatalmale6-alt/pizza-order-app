import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class ToppingDialog extends StatefulWidget {
  final List<ToppingItem> availableToppings;
  const ToppingDialog({super.key, required this.availableToppings});

  @override
  State<ToppingDialog> createState() => _ToppingDialogState();
}

class _ToppingDialogState extends State<ToppingDialog> {
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Customize Pizza / เลือกท็อปปิ้ง',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableToppings.length,
                  itemBuilder: (context, index) {
                    final topping = widget.availableToppings[index];
                    final selected = _selectedIndices.contains(index);
                    return CheckboxListTile(
                      title: Text(
                        '${topping.nameThai} / ${topping.name}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text('+${topping.price.toInt()} THB'),
                      value: selected,
                      activeColor: Colors.deepOrange,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIndices.add(index);
                          } else {
                            _selectedIndices.remove(index);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel / ยกเลิก'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final selected = _selectedIndices.map((i) {
                        final t = widget.availableToppings[i];
                        return SelectedTopping(
                          name: t.name,
                          nameThai: t.nameThai,
                          price: t.price,
                        );
                      }).toList();
                      Navigator.pop(context, selected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Pizza / เพิ่มพิซซ่า'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
