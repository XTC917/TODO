import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the system browser (never in-app).
Future<bool> launchExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;

  try {
    if (!await canLaunchUrl(uri)) return false;
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
