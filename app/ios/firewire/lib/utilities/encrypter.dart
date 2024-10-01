import 'package:encrypt/encrypt.dart' as encrypt;


class EncryptAES {
  late encrypt.Encrypter encrypter;
  //final encryptionKey = encrypt.Key.fromSecureRandom(32);
  //final encryptionIV = encrypt.IV.fromSecureRandom(16);
  final encryptionKey = encrypt.Key.fromBase64("INzTaqyeWYGbjMEKK8q20WS09qF8BbOkK/3CJr+gDpM=");
  final encryptionIV = encrypt.IV.fromBase64("b4BAvtNrgPQGnd/o7m1aug==");

  EncryptAES () {
    print(encryptionKey.base64);
    print(encryptionIV.base64);
    encrypter = encrypt.Encrypter(encrypt.AES(encryptionKey));
  }

  encrypt.Encrypted encryptData(String text) {
    final encrypted = encrypter.encrypt(text, iv: encryptionIV);

    return encrypted;
  }

  String decryptData(encrypt.Encrypted text) {
    final decrypted = encrypter.decrypt(text, iv: encryptionIV);

    return decrypted;
  }

}