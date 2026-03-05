class ShippingInfo {
  const ShippingInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
  });

  final String name;
  final String phone;
  final String address;
  final String city;
  final String country;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
    };
  }
}
