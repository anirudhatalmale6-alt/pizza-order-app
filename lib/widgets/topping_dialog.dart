import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class ToppingDialog extends StatefulWidget {
  final List<ToppingItem> availableToppings;
  final String categoryLabel;
  final List<SelectedTopping>? initialSelection;
  final bool isEditing;
  const ToppingDialog({super.key, required this.availableToppings, this.categoryLabel = 'Pizza', this.initialSelection, this.isEditing = false});

  @override
  State<ToppingDialog> createState() => _ToppingDialogState();
}

class _ToppingDialogState extends State<ToppingDialog> {
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      for (final sel in widget.initialSelection!) {
        final idx = widget.availableToppings.indexWhere((t) => t.name == sel.name);
        if (idx >= 0) _selectedIndices.add(idx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SizedBox(
        height: screenHeight * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Customize ${widget.categoryLabel} / เลือกตัวเลือก',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${widget.availableToppings.length} options available',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.availableToppings.length,
                  itemBuilder: (context, index) {
                    final topping = widget.availableToppings[index];
                    final selected = _selectedIndices.contains(index);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      color: selected
                          ? Colors.deepOrange.shade50
                          : null,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedIndices.remove(index);
                            } else {
                              _selectedIndices.add(index);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: selected
                                    ? Colors.deepOrange
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${topping.nameThai} / ${topping.name}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    Text(
                                      '+${topping.price.toInt()} THB',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                    child: Text(widget.isEditing ? 'Update / อัปเดต' : 'Add ${widget.categoryLabel} / เพิ่ม'),
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
