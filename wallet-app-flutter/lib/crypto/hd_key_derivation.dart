import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// BIP-32 HD key derivation for Cosmos-compatible wallets.
///
/// Derives child keys from a seed using the standard HD wallet path
/// m/44'/118'/0'/0/N for Cosmos (coin type 118).
class HdKeyDerivation {
  const HdKeyDerivation._();

  /// Cosmos coin type per SLIP-44
  static const int cosmosCoinType = 118;

  /// Soulon-specific coin type (using Cosmos default for now)
  static const int soulonCoinType = 118;

  /// Default derivation path template: m/44'/{coinType}'/0'/0/{index}
  static String derivationPath({int coinType = cosmosCoinType, int index = 0}) {
    return "m/44'/$coinType'/0'/0/$index";
  }

  /// Derives a master key from a BIP-39 seed using HMAC-SHA512.
  ///
  /// Returns (privateKey, chainCode) each 32 bytes.
  static (Uint8List, Uint8List) masterKeyFromSeed(Uint8List seed) {
    final hmac = Hmac(sha512, utf8.encode('Bitcoin seed'));
    final digest = hmac.convert(seed);
    final bytes = Uint8List.fromList(digest.bytes);
    final privateKey = Uint8List.sublistView(bytes, 0, 32);
    final chainCode = Uint8List.sublistView(bytes, 32, 64);
    return (privateKey, chainCode);
  }

  /// Derives a hardened child key at the given index.
  ///
  /// For hardened derivation, index must have 0x80000000 bit set.
  static (Uint8List, Uint8List) deriveHardenedChild(
    Uint8List parentKey,
    Uint8List parentChainCode,
    int index,
  ) {
    final data = Uint8List(37);
    data[0] = 0x00;
    data.setRange(1, 33, parentKey);
    data[33] = (index >> 24) & 0xFF;
    data[34] = (index >> 16) & 0xFF;
    data[35] = (index >> 8) & 0xFF;
    data[36] = index & 0xFF;

    final hmac = Hmac(sha512, parentChainCode);
    final digest = hmac.convert(data);
    final bytes = Uint8List.fromList(digest.bytes);

    final childKey = Uint8List.sublistView(bytes, 0, 32);
    final childChainCode = Uint8List.sublistView(bytes, 32, 64);
    return (childKey, childChainCode);
  }

  /// Derives a private key following the BIP-44 path for Cosmos.
  ///
  /// Path: m/44'/118'/0'/0/{index}
  static Uint8List derivePrivateKey(Uint8List seed, {int coinType = cosmosCoinType, int index = 0}) {
    var (key, chainCode) = masterKeyFromSeed(seed);

    // m/44' (hardened)
    (key, chainCode) = deriveHardenedChild(key, chainCode, 44 | 0x80000000);
    // m/44'/118' (hardened)
    (key, chainCode) = deriveHardenedChild(key, chainCode, coinType | 0x80000000);
    // m/44'/118'/0' (hardened)
    (key, chainCode) = deriveHardenedChild(key, chainCode, 0 | 0x80000000);
    // m/44'/118'/0'/0 (hardened for compatibility)
    // WARNING: BIP-44 specifies non-hardened derivation for the last two levels
    // (change=0 and index=N). This implementation uses hardened derivation for
    // all levels because normal (non-hardened) child derivation requires
    // secp256k1 point addition (pubkey + child offset), which needs a native
    // SigningBackend implementation. Addresses derived here will NOT match
    // standard wallets (Keplr, Cosmostation, Leap). Once a native secp256k1
    // backend is available, replace these two calls with deriveNormalChild().
    (key, chainCode) = deriveHardenedChild(key, chainCode, 0 | 0x80000000);
    // m/44'/118'/0'/0/{index} (hardened)
    // TODO: Replace with normal derivation: deriveNormalChild(key, chainCode, index)
    (key, chainCode) = deriveHardenedChild(key, chainCode, index | 0x80000000);

    return key;
  }
}
