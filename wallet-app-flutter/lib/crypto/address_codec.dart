import 'dart:typed_data';

/// Bech32 address encoding/decoding for Cosmos-compatible chains.
///
/// Encodes raw public key hashes into human-readable addresses like `soulon1...`
/// and decodes them back to raw bytes.
class AddressCodec {
  const AddressCodec._();

  /// Default human-readable part for Soulon chain
  static const String soulonHrp = 'soulon';

  /// Cosmos hub HRP
  static const String cosmosHrp = 'cosmos';

  static const String _bech32Charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  /// Encodes raw address bytes to a Bech32 string.
  static String encode(String hrp, Uint8List data) {
    final converted = _convertBits(data, 8, 5, true);
    if (converted == null) {
      throw FormatException('Failed to convert address bytes to 5-bit groups');
    }
    final checksum = _createChecksum(hrp, converted);
    final combined = [...converted, ...checksum];

    final result = StringBuffer('$hrp${'1'}');
    for (final value in combined) {
      result.write(_bech32Charset[value]);
    }
    return result.toString();
  }

  /// Decodes a Bech32 string to (hrp, data bytes).
  static (String, Uint8List) decode(String bech32String) {
    final input = bech32String.toLowerCase();
    final pos = input.lastIndexOf('1');
    if (pos < 1 || pos + 7 > input.length) {
      throw const FormatException('Invalid Bech32 separator position');
    }

    final hrp = input.substring(0, pos);
    final dataChars = input.substring(pos + 1);

    final data = <int>[];
    for (var i = 0; i < dataChars.length; i++) {
      final index = _bech32Charset.indexOf(dataChars[i]);
      if (index == -1) {
        throw FormatException('Invalid Bech32 character: ${dataChars[i]}');
      }
      data.add(index);
    }

    if (!_verifyChecksum(hrp, data)) {
      throw const FormatException('Invalid Bech32 checksum');
    }

    final payload = data.sublist(0, data.length - 6);
    final converted = _convertBits(Uint8List.fromList(payload), 5, 8, false);
    if (converted == null) {
      throw const FormatException('Failed to convert 5-bit groups to bytes');
    }

    return (hrp, converted);
  }

  /// Validates a Bech32 address string.
  static bool isValid(String address, {String? expectedHrp}) {
    try {
      final (hrp, _) = decode(address);
      if (expectedHrp != null && hrp != expectedHrp) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<int> _createChecksum(String hrp, List<int> data) {
    final values = [..._hrpExpand(hrp), ...data, 0, 0, 0, 0, 0, 0];
    final polymod = _polymod(values) ^ 1;
    final result = <int>[];
    for (var i = 0; i < 6; i++) {
      result.add((polymod >> (5 * (5 - i))) & 31);
    }
    return result;
  }

  static bool _verifyChecksum(String hrp, List<int> data) {
    return _polymod([..._hrpExpand(hrp), ...data]) == 1;
  }

  static List<int> _hrpExpand(String hrp) {
    final result = <int>[];
    for (var i = 0; i < hrp.length; i++) {
      result.add(hrp.codeUnitAt(i) >> 5);
    }
    result.add(0);
    for (var i = 0; i < hrp.length; i++) {
      result.add(hrp.codeUnitAt(i) & 31);
    }
    return result;
  }

  static int _polymod(List<int> values) {
    const generator = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
    var chk = 1;
    for (final value in values) {
      final top = chk >> 25;
      chk = (chk & 0x1ffffff) << 5 ^ value;
      for (var i = 0; i < 5; i++) {
        if ((top >> i) & 1 == 1) {
          chk ^= generator[i];
        }
      }
    }
    return chk;
  }

  static Uint8List? _convertBits(Uint8List data, int fromBits, int toBits, bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << toBits) - 1;

    for (final value in data) {
      if (value < 0 || (value >> fromBits) != 0) {
        return null;
      }
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (toBits - bits)) & maxv);
      }
    } else {
      if (bits >= fromBits) {
        return null;
      }
      if (((acc << (toBits - bits)) & maxv) != 0) {
        return null;
      }
    }

    return Uint8List.fromList(result);
  }
}
