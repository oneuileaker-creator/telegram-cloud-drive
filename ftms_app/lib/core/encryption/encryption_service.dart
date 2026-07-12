import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:convert/convert.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;
  EncryptionService._();

  static const _storage    = FlutterSecureStorage();
  static const _keyName    = 'ftms_encryption_key';
  static const _saltName   = 'ftms_key_salt';

  final _algorithm = AesGcm.with256bits();

  // ── Key Management ────────────────────────────────────────

  Future<SecretKey> _getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      final keyBytes = hex.decode(existing);
      return SecretKey(keyBytes);
    }
    // Generate new key
    final key = await _algorithm.newSecretKey();
    final keyBytes = await key.extractBytes();
    await _storage.write(key: _keyName, value: hex.encode(keyBytes));
    return key;
  }

  Future<String> exportKeyAsBase64() async {
    final key = await _getOrCreateKey();
    final bytes = await key.extractBytes();
    return base64.encode(bytes);
  }

  Future<void> importKeyFromBase64(String encoded) async {
    final bytes = base64.decode(encoded);
    await _storage.write(key: _keyName, value: hex.encode(bytes));
  }

  Future<bool> hasKey() async {
    return await _storage.read(key: _keyName) != null;
  }

  // ── Encrypt ───────────────────────────────────────────────

  Future<EncryptedData> encryptFile(Uint8List data) async {
    final key = await _getOrCreateKey();

    // Random nonce
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      data,
      secretKey: key,
      nonce: nonce,
    );

    return EncryptedData(
      ciphertext: Uint8List.fromList(secretBox.cipherText),
      nonce:      Uint8List.fromList(secretBox.nonce),
      mac:        Uint8List.fromList(secretBox.mac.bytes),
    );
  }

  // ── Decrypt ───────────────────────────────────────────────

  Future<Uint8List> decryptFile(EncryptedData encrypted) async {
    final key = await _getOrCreateKey();

    final secretBox = SecretBox(
      encrypted.ciphertext.toList(),
      nonce: encrypted.nonce.toList(),
      mac:   Mac(encrypted.mac.toList()),
    );

    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(decrypted);
  }

  // ── Encrypt bytes to uploadable format ────────────────────
  // Format: [4 bytes nonce_len][nonce][4 bytes mac_len][mac][ciphertext]

  Future<Uint8List> encryptToBytes(Uint8List plaintext) async {
    final encrypted = await encryptFile(plaintext);

    final buffer = BytesBuilder();

    // Nonce
    final nonceLenBytes = ByteData(4)
      ..setInt32(0, encrypted.nonce.length, Endian.big);
    buffer.add(nonceLenBytes.buffer.asUint8List());
    buffer.add(encrypted.nonce);

    // MAC
    final macLenBytes = ByteData(4)
      ..setInt32(0, encrypted.mac.length, Endian.big);
    buffer.add(macLenBytes.buffer.asUint8List());
    buffer.add(encrypted.mac);

    // Ciphertext
    buffer.add(encrypted.ciphertext);

    return buffer.toBytes();
  }

  Future<Uint8List> decryptFromBytes(Uint8List encryptedBytes) async {
    int offset = 0;

    // Read nonce
    final nonceLen = ByteData.view(
      encryptedBytes.buffer, offset, 4,
    ).getInt32(0, Endian.big);
    offset += 4;
    final nonce = encryptedBytes.sublist(offset, offset + nonceLen);
    offset += nonceLen;

    // Read MAC
    final macLen = ByteData.view(
      encryptedBytes.buffer, offset, 4,
    ).getInt32(0, Endian.big);
    offset += 4;
    final mac = encryptedBytes.sublist(offset, offset + macLen);
    offset += macLen;

    // Read ciphertext
    final ciphertext = encryptedBytes.sublist(offset);

    return decryptFile(EncryptedData(
      ciphertext: ciphertext,
      nonce:      nonce,
      mac:        mac,
    ));
  }
}

class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  const EncryptedData({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });
}
