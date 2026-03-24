import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// BIP-39 mnemonic word list operations.
///
/// Generates and validates 12/24-word mnemonic phrases for HD wallet seed derivation.
class MnemonicGenerator {
  MnemonicGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Generates entropy bytes for a mnemonic phrase.
  ///
  /// [strength] is the number of bits: 128 for 12 words, 256 for 24 words.
  Uint8List generateEntropy({int strength = 128}) {
    if (strength != 128 && strength != 160 && strength != 192 && strength != 224 && strength != 256) {
      throw ArgumentError('Strength must be one of 128, 160, 192, 224, 256');
    }
    final byteCount = strength ~/ 8;
    final bytes = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// Derives a checksum from entropy bytes.
  Uint8List deriveChecksum(Uint8List entropy) {
    final hash = sha256.convert(entropy);
    return Uint8List.fromList(hash.bytes);
  }

  /// Converts entropy bytes to a list of 11-bit indices.
  List<int> entropyToIndices(Uint8List entropy) {
    final checksumBits = entropy.length ~/ 4;
    final checksum = deriveChecksum(entropy);

    final bits = StringBuffer();
    for (final byte in entropy) {
      bits.write(byte.toRadixString(2).padLeft(8, '0'));
    }
    for (var i = 0; i < checksumBits; i++) {
      bits.write((checksum[0] >> (7 - i)) & 1);
    }

    final bitString = bits.toString();
    final indices = <int>[];
    for (var i = 0; i < bitString.length; i += 11) {
      if (i + 11 <= bitString.length) {
        indices.add(int.parse(bitString.substring(i, i + 11), radix: 2));
      }
    }
    return indices;
  }

  /// Validates that a list of mnemonic word indices has a valid checksum.
  bool validateIndices(List<int> indices) {
    if (indices.length != 12 && indices.length != 15 && indices.length != 18 &&
        indices.length != 21 && indices.length != 24) {
      return false;
    }

    final totalBits = indices.length * 11;
    final checksumBits = totalBits ~/ 33;
    final entropyBits = totalBits - checksumBits;

    final bits = StringBuffer();
    for (final index in indices) {
      bits.write(index.toRadixString(2).padLeft(11, '0'));
    }
    final bitString = bits.toString();

    final entropyBytes = Uint8List(entropyBits ~/ 8);
    for (var i = 0; i < entropyBytes.length; i++) {
      entropyBytes[i] = int.parse(bitString.substring(i * 8, i * 8 + 8), radix: 2);
    }

    final expectedChecksum = deriveChecksum(entropyBytes);
    final checksumBitString = bitString.substring(entropyBits);

    final expectedBits = StringBuffer();
    for (var i = 0; i < checksumBits; i++) {
      expectedBits.write((expectedChecksum[0] >> (7 - i)) & 1);
    }

    return checksumBitString == expectedBits.toString();
  }
}
