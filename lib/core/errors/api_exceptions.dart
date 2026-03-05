class ApiUnauthorizedException implements Exception {
  const ApiUnauthorizedException([this.message = 'Unauthorized']);

  final String message;

  @override
  String toString() => message;
}
