import 'package:flutter/material.dart';
import '../../core/models/food.dart';

class PackWidget extends StatelessWidget {
  const PackWidget({super.key, required this.food, this.small = false});
  final Food food;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final Color packBgColor = switch (food.tone) {
      'brown' => const Color(0xFF6E4D3B),
      'green' => const Color(0xFF4D6E42),
      'gold' => const Color(0xFFB08638),
      _ => const Color(0xFF7B8B94),
    };

    return Container(
      width: small ? 58 : 120,
      height: small ? 72 : 155,
      padding: EdgeInsets.all(small ? 4 : 8),
      decoration: BoxDecoration(
        color: packBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            food.brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 7 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: small ? 4 : 8, horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.eco,
                  size: small ? 14 : 24,
                  color: packBgColor,
                ),
                const SizedBox(height: 2),
                Text(
                  food.name.replaceAll('Bánh ', '').replaceAll('Thanh ', ''),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: packBgColor,
                    fontSize: small ? 6.5 : 10,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            food.weight,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: small ? 6 : 9,
            ),
          ),
        ],
      ),
    );
  }
}
