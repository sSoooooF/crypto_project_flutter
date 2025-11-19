import 'dart:typed_data';
import 'tables.dart';

Uint8List subBytes(Uint8List block) =>
    Uint8List.fromList(block.map((b) => KUZ_PI[b]).toList());

Uint8List invSubBytes(Uint8List block) =>
    Uint8List.fromList(block.map((b) => KUZ_PI_INV[b]).toList());
