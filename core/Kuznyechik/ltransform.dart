import 'dart:typed_data';
import 'utils.dart'; 
import 'tables.dart'; 

// Вспомогательная функция R (сдвиг регистра)
Uint8List _R(Uint8List state) {
  int a15 = 0; // Это будет новый байт (sigma)
  for (int i = 0; i < 16; i++) {
    a15 ^= gfMul(state[i], L_COEFFS[i]);
  }

  Uint8List result = Uint8List(16);
  // Сдвигаем: state[0] переходит в result[1] и т.д.
  for (int i = 1; i < 16; i++) {
    result[i] = state[i - 1];
  }
  result[0] = a15; // Новый байт ставится в начало
  return result;
}

Uint8List lTransform(Uint8List block) {
  Uint8List temp = Uint8List.fromList(block);
  // L-преобразование — это 16 применений функции R
  for (int i = 0; i < 16; i++) {
    temp = _R(temp);
  }
  return temp;
}

// Вспомогательная функция invR (обратный сдвиг)
Uint8List _invR(Uint8List state) {
  Uint8List result = Uint8List(16);
  
  // Восстанавливаем сдвиг: state[1] возвращается в result[0]
  for (int i = 0; i < 15; i++) {
    result[i] = state[i + 1];
  }
  
  // Восстанавливаем последний байт
  int sum = state[0]; 
  for (int i = 0; i < 15; i++) {
    sum ^= gfMul(result[i], L_COEFFS[i]);
  }
  result[15] = sum; // L_COEFFS[15] == 1, деление не нужно
  
  return result;
}

Uint8List invLTransform(Uint8List block) {
  Uint8List temp = Uint8List.fromList(block);
  for (int i = 0; i < 16; i++) {
    temp = _invR(temp);
  }
  return temp;
}