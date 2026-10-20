import 'package:url_launcher/url_launcher.dart';

/// Builds and opens contact links (WhatsApp, phone, email).
abstract final class Contact {
  static String digitsOnly(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  static Uri whatsApp(String phone, {String message = 'Hello'}) => Uri.parse(
      'https://wa.me/${digitsOnly(phone)}?text=${Uri.encodeComponent(message)}');

  static Uri call(String phone) =>
      Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));

  static Uri email(String to, {String? subject, String? body}) {
    final params = <String, String>{
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    };
    return Uri(
      scheme: 'mailto',
      path: to,
      // mailto clients expect %20 rather than '+', so encode manually.
      query: params.isEmpty
          ? null
          : params.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&'),
    );
  }

  /// Opens [uri] in an external app. Returns false if nothing could handle it.
  static Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
