class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  String? accessToken;
  String? refreshToken;

  void saveTokens({required String access, required String refresh}) {
    accessToken = access;
    refreshToken = refresh;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}
