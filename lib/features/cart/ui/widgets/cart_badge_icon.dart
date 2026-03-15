import 'package:flutter/material.dart';

import '../../data/cart_controller.dart';
import '../cart_page.dart';

// ═══════════════════════════════════════════════════════════════════
// CART BADGE ICON  —  logique originale 100 % préservée
// ═══════════════════════════════════════════════════════════════════
class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    CartController.instance.ensureLoaded(); // original
    return AnimatedBuilder(
      animation: CartController.instance, // original
      builder: (context, _) {
        final int count = CartController.instance.totalCount; // original
        return GestureDetector(
          onTap: () {
            // original navigation
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartPage()));
          },
          child: Container(
            width: 38, height: 38,
            margin: const EdgeInsets.only(right: 4),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Icône panier
                const Icon(Icons.shopping_cart_outlined,
                    color: Color(0xFFB8C8DC), size: 20),

                // Badge count (original condition: count > 0)
                if (count > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0078CC), Color(0xFF00A8FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00A8FF).withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      // original logic: count > 99 ? '99+' : '$count'
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}