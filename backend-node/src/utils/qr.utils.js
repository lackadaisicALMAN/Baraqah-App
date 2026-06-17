'use strict';

const QRCode = require('qrcode');

/**
 * Generate a QR code data URL encoding the check-in token payload.
 * @param {string} qrToken - UUID token
 * @param {string} sessionId
 * @returns {Promise<string>} data URL
 */
async function generateQrDataUrl(qrToken, sessionId) {
  const payload = JSON.stringify({
    type: 'BARAQAH_CHECKIN',
    qrToken,
    sessionId,
    v: 1,
  });
  return QRCode.toDataURL(payload, {
    errorCorrectionLevel: 'M',
    margin: 2,
    width: 300,
  });
}

/**
 * Parse QR scan payload from client.
 * @param {string} rawPayload
 * @returns {{ qrToken: string, sessionId: string }|null}
 */
function parseQrPayload(rawPayload) {
  try {
    const parsed = JSON.parse(rawPayload);
    if (parsed.type === 'BARAQAH_CHECKIN' && parsed.qrToken && parsed.sessionId) {
      return { qrToken: parsed.qrToken, sessionId: parsed.sessionId };
    }
    return null;
  } catch {
    return null;
  }
}

module.exports = { generateQrDataUrl, parseQrPayload };
