import 'package:flutter/material.dart';

class CommandSlider extends StatelessWidget {
  const CommandSlider({super.key, required this.max, required this.id, this.value, required this.setValue});
  final int max;
  final int id;
  final int? value;
  final Function(int, int) setValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            min: 0,
            max: max.toDouble(),
            divisions: max,
            value: value == null ? 0 : value!.toDouble(),
            label: value == null ? '?' : value!.toString(),
            onChanged: (newValue) => setValue(id, newValue.round()),
          ),
        ),
        value == null ? const Icon(Icons.question_mark) : const Icon(Icons.check)
      ],
    );
  }
}
