class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://scamshield-backend-f0wc.onrender.com/api',
  );
  static Uri get apiBaseUri {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const FormatException(
        'API_BASE_URL must be an absolute HTTP or HTTPS URL.',
      );
    }
    return uri.replace(
      path: uri.path.replaceFirst(RegExp(r'/+$'), ''),
      query: null,
      fragment: null,
    );
  }
}
