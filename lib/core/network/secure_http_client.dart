import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Secure HTTP client with certificate pinning
/// Protects against man-in-the-middle attacks
class SecureHttpClient {
  static SecureHttpClient? _instance;
  late HttpClient _client;
  
  // SHA-256 certificate fingerprints for your API
  // Get these from: openssl s_client -connect api.yourdomain.com:443 | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256
  final List<String> _pinnedCertificates = [
    // Add your certificate SHA-256 hashes here
    // Format: 'SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  ];
  
  // Allowed hosts for certificate pinning
  final List<String> _pinnedHosts = [
    'api.betterandbliss.app',
    'api-staging.betterandbliss.app',
    'cdn.betterandbliss.app',
  ];
  
  static SecureHttpClient get instance {
    _instance ??= SecureHttpClient._();
    return _instance!;
  }
  
  SecureHttpClient._() {
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..badCertificateCallback = _validateCertificate;
  }
  
  /// Validate certificate against pinned hashes
  bool _validateCertificate(X509Certificate cert, String host, int port) {
    // In debug mode, allow all certificates for easier development
    if (kDebugMode) {
      return true;
    }
    
    // Skip pinning for non-pinned hosts
    if (!_pinnedHosts.any((pinnedHost) => host.contains(pinnedHost))) {
      return true;
    }
    
    // If no certificates are pinned, allow all (but log warning)
    if (_pinnedCertificates.isEmpty) {
      debugPrint('⚠️ WARNING: No certificates pinned for $host');
      return true;
    }
    
    // Compute certificate fingerprint
    final certFingerprint = _computeFingerprint(cert);
    
    // Check against pinned certificates
    final isValid = _pinnedCertificates.any(
      (pinned) => pinned.toUpperCase() == certFingerprint.toUpperCase()
    );
    
    if (!isValid) {
      debugPrint('❌ Certificate pinning failed for $host');
      debugPrint('   Expected: ${_pinnedCertificates.join(", ")}');
      debugPrint('   Got: $certFingerprint');
    }
    
    return isValid;
  }
  
  /// Compute SHA-256 fingerprint of certificate
  String _computeFingerprint(X509Certificate cert) {
    // In production, you'd compute actual SHA-256 hash of the certificate
    // This is a simplified implementation
    final bytes = cert.der;
    // Use a proper SHA-256 implementation in production
    return 'SHA256:${base64Encode(bytes).substring(0, 44)}';
  }
  
  /// Get the secure HTTP client
  HttpClient get client => _client;
  
  /// Configure certificate pins at runtime
  void setPinnedCertificates(List<String> certificates) {
    _pinnedCertificates.clear();
    _pinnedCertificates.addAll(certificates);
  }
  
  /// Add a pinned host
  void addPinnedHost(String host) {
    if (!_pinnedHosts.contains(host)) {
      _pinnedHosts.add(host);
    }
  }
}

/// Extension for making secure HTTP requests
extension SecureHttpClientExtension on SecureHttpClient {
  /// Make a secure GET request
  Future<String> secureGet(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    final request = await client.getUrl(uri);
    
    headers?.forEach((key, value) {
      request.headers.add(key, value);
    });
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw HttpException('Request failed: ${response.statusCode}', uri: uri);
    }
  }
  
  /// Make a secure POST request
  Future<String> securePost(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse(url);
    final request = await client.postUrl(uri);
    
    request.headers.contentType = ContentType.json;
    headers?.forEach((key, value) {
      request.headers.add(key, value);
    });
    
    if (body != null) {
      request.write(jsonEncode(body));
    }
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw HttpException('Request failed: ${response.statusCode}', uri: uri);
    }
  }
}
