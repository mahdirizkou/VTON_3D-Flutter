import 'package:flutter/material.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../auth/ui/login_page.dart';
import '../../cart/data/cart_controller.dart';
import '../../cart/models/cart_item.dart';
import '../data/orders_api.dart';
import '../models/order.dart';
import '../models/shipping_info.dart';
import 'order_success_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.items,
    required this.shipping,
    required this.total,
  });

  final List<CartItem> items;
  final ShippingInfo shipping;
  final double total;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final OrdersApi _ordersApi = OrdersApi();

  bool _isPaying = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mock Card Payment', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Card Number'),
                      validator: (value) {
                        final cleaned = (value ?? '').replaceAll(' ', '');
                        if (cleaned.length < 12 || cleaned.length > 19) {
                          return 'Enter a valid card number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            decoration: const InputDecoration(labelText: 'MM/YY'),
                            validator: (value) {
                              final v = (value ?? '').trim();
                              if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
                                return 'MM/YY';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _cvcController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'CVC'),
                            validator: (value) {
                              final v = (value ?? '').trim();
                              if (!RegExp(r'^\d{3,4}$').hasMatch(v)) {
                                return 'Invalid CVC';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Total: \$${widget.total.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: _isPaying ? null : _pay,
            child: _isPaying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Payment'),
          ),
        ),
      ),
    );
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPaying = true);
    try {
      final Order order = await _ordersApi.createOrder(
        items: widget.items,
        shipping: widget.shipping,
        paymentMethod: 'mock_card',
      );

      await CartController.instance.clearCart();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            order: order,
            items: widget.items,
          ),
        ),
        (route) => false,
      );
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await TokenStore.instance.clearTokens();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }
}
