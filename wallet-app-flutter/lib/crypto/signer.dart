import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'address_codec.dart';

/// Transaction signer for Cosmos SIGN_MODE_DIRECT.
///
/// Constructs and signs transaction payloads for Soulon/Cosmos chains.
/// Note: secp256k1 ECDSA signing requires a native FFI or platform channel
/// implementation. This module provides the message preparation and
/// hash computation, with a pluggable signing backend.
abstract class SigningBackend {
  /// Signs a 32-byte message hash with the given private key.
  /// Returns the 64-byte (r, s) signature.
  Future<Uint8List> sign(Uint8List messageHash, Uint8List privateKey);

  /// Derives the compressed public key (33 bytes) from a private key.
  Uint8List publicKeyFromPrivate(Uint8List privateKey);
}

/// Cosmos transaction signer.
class CosmosSigner {
  CosmosSigner({required this.backend});

  final SigningBackend backend;

  /// Computes the signing hash for a Cosmos SIGN_MODE_DIRECT transaction.
  ///
  /// The sign doc is SHA-256 hashed before signing.
  Uint8List computeSignHash(Uint8List signDocBytes) {
    final hash = sha256.convert(signDocBytes);
    return Uint8List.fromList(hash.bytes);
  }

  /// Signs a Cosmos transaction sign doc.
  Future<Uint8List> signDirect(Uint8List signDocBytes, Uint8List privateKey) async {
    final hash = computeSignHash(signDocBytes);
    return backend.sign(hash, privateKey);
  }

  /// Derives the Bech32 address from a private key.
  String deriveAddress(Uint8List privateKey, {String hrp = AddressCodec.soulonHrp}) {
    final pubKey = backend.publicKeyFromPrivate(privateKey);
    // Cosmos address = RIPEMD160(SHA256(compressedPubKey))
    final sha256Hash = sha256.convert(pubKey);
    // WARNING: Using truncated SHA256 as a placeholder. This produces addresses
    // that are INCOMPATIBLE with real Cosmos chains. For production, integrate
    // pointycastle's RIPEMD160 or use a platform channel/FFI binding.
    // TODO: Replace with RIPEMD160 once a crypto backend is available.
    final addressBytes = Uint8List.fromList(sha256Hash.bytes.sublist(0, 20));
    return AddressCodec.encode(hrp, addressBytes);
  }

  /// Builds a simple bank/MsgSend sign doc (simplified protobuf representation).
  Map<String, dynamic> buildBankSendSignDoc({
    required String fromAddress,
    required String toAddress,
    required String amount,
    required String denom,
    required String chainId,
    required int accountNumber,
    required int sequence,
    String memo = '',
    int gasLimit = 200000,
    String feeAmount = '500',
    String feeDenom = 'usoul',
  }) {
    return {
      'body': {
        'messages': [
          {
            '@type': '/cosmos.bank.v1beta1.MsgSend',
            'from_address': fromAddress,
            'to_address': toAddress,
            'amount': [
              {'denom': denom, 'amount': amount},
            ],
          },
        ],
        'memo': memo,
      },
      'auth_info': {
        'signer_infos': [],
        'fee': {
          'amount': [
            {'denom': feeDenom, 'amount': feeAmount},
          ],
          'gas_limit': gasLimit.toString(),
        },
      },
      'chain_id': chainId,
      'account_number': accountNumber.toString(),
      'sequence': sequence.toString(),
    };
  }

  /// Serializes a sign doc to bytes for signing.
  Uint8List serializeSignDoc(Map<String, dynamic> signDoc) {
    final jsonString = json.encode(signDoc);
    return Uint8List.fromList(utf8.encode(jsonString));
  }
}
