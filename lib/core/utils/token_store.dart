class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  String? _accessToken;
  String? _refreshToken;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _accessToken = access;
    _refreshToken = refresh;
  }

  Future<String?> getAccessToken() async {
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
