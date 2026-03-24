import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// AES-256-GCM-based encrypted keystore for private key storage.
///
/// Encrypts private keys with a password-derived key for secure local persistence.
/// Uses PBKDF2-HMAC-SHA256 for key derivation.
class KeystoreManager {
  const KeystoreManager._();

  /// Number of PBKDF2 iterations for key derivation.
  static const int pbkdf2Iterations = 100000;

  /// Salt length in bytes.
  static const int saltLength = 32;

  /// Derives an encryption key from a password using PBKDF2-HMAC-SHA256.
  ///
  /// Returns a 32-byte key suitable for AES-256.
  static Uint8List deriveKey(String password, Uint8List salt, {int iterations = pbkdf2Iterations}) {
    final passwordBytes = utf8.encode(password);

    // PBKDF2-HMAC-SHA256 implementation
    var block = Uint8List(32);

    final hmac = Hmac(sha256, passwordBytes);

    // First block (we only need one 32-byte block for AES-256)
    final input = Uint8List(salt.length + 4);
    input.setRange(0, salt.length, salt);
    input[salt.length] = 0;
    input[salt.length + 1] = 0;
    input[salt.length + 2] = 0;
    input[salt.length + 3] = 1;

    var prev = Uint8List.fromList(hmac.convert(input).bytes);
    block = Uint8List.fromList(prev);

    for (var i = 1; i < iterations; i++) {
      final next = Uint8List.fromList(hmac.convert(prev).bytes);
      for (var j = 0; j < 32; j++) {
        block[j] ^= next[j];
      }
      prev = next;
    }

    return block;
  }

  /// Serializes a keystore entry to a JSON-compatible map.
  ///
  /// The map contains the encrypted private key, salt, and metadata
  /// needed for decryption. The actual encryption should be performed
  /// using platform-specific AES-256-GCM (via MethodChannel or FFI).
  static Map<String, dynamic> serializeKeystoreEntry({
    required String address,
    required Uint8List encryptedKey,
    required Uint8List salt,
    required Uint8List nonce,
    required String derivationPath,
    int iterations = pbkdf2Iterations,
  }) {
    return {
      'version': 1,
      'address': address,
      'crypto': {
        'cipher': 'aes-256-gcm',
        'ciphertext': base64Encode(encryptedKey),
        'nonce': base64Encode(nonce),
        'kdf': 'pbkdf2-hmac-sha256',
        'kdfparams': {
          'iterations': iterations,
          'salt': base64Encode(salt),
          'dklen': 32,
        },
      },
      'derivationPath': derivationPath,
    };
  }

  /// Deserializes a keystore entry from a JSON-compatible map.
  static ({
    String address,
    Uint8List encryptedKey,
    Uint8List salt,
    Uint8List nonce,
    String derivationPath,
    int iterations,
  }) deserializeKeystoreEntry(Map<String, dynamic> json) {
    final crypto = json['crypto'] as Map<String, dynamic>;
    final kdfparams = crypto['kdfparams'] as Map<String, dynamic>;

    return (
      address: json['address'] as String,
      encryptedKey: base64Decode(crypto['ciphertext'] as String),
      salt: base64Decode(kdfparams['salt'] as String),
      nonce: base64Decode(crypto['nonce'] as String),
      derivationPath: json['derivationPath'] as String,
      iterations: kdfparams['iterations'] as int,
    );
  }
}
