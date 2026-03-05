import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../cart/models/cart_item.dart';
import '../models/order.dart';
import '../models/shipping_info.dart';

class OrdersApi {
  OrdersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Order> createOrder({
    required List<CartItem> items,
    required ShippingInfo shipping,
    String paymentMethod = 'mock_card',
  }) async {
    final access = await TokenStore.instance.getAccessToken();
    if (access == null || access.isEmpty) {
      throw const ApiUnauthorizedException('No access token. Please log in again.');
    }

    final response = await _client.post(
      Uri.parse('$kBaseUrl/api/orders/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $access',
      },
      body: jsonEncode({
        'items': items
            .map(
              (e) => {
                'glasses_id': e.itemId,
                'quantity': e.quantity,
              },
            )
            .toList(),
        'shipping': shipping.toJson(),
        'payment_method': paymentMethod,
      }),
    );

    if (response.statusCode == 401) {
      throw const ApiUnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Order.fromJson(data);
    }

    throw Exception(_readError(response.body));
  }

  String _readError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded['detail'] != null) return decoded['detail'].toString();
      if (decoded['message'] != null) return decoded['message'].toString();
      if (decoded.isNotEmpty) return decoded.values.first.toString();
    } catch (_) {}
    return 'Could not create order.';
  }
}
