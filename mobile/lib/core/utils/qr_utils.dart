// QR scanning is handled in-app via session ID matching.
// This stub replaces the removed qr_code_scanner package.
class QRUtils {
  static bool isValidQr(String? code) {
    return code != null && code.isNotEmpty;
  }
}
