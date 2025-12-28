import 'package:compartimos_gastos/controllers/pay_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayController Matemáticas', () {
    final controller = PayController();

    // PRUEBA 1
    test('Dividir 10€ entre 3 personas reparte los céntimos correctamente', () {
      final double total = 10.00;
      final participantes = ['Jose', 'Miguel', 'Hector'];

      final resultado = controller.calcularDistribucion(total, participantes);

      // Esperamos que: 3.34 + 3.33 + 3.33 = 10.00
      // El algoritmo le da un céntimo más al primero para cuadrar.

      expect(resultado['Jose'], 3.34);
      expect(resultado['Miguel'], 3.33);
      expect(resultado['Hector'], 3.33);

      // Verificamos que la suma total sea exacta cogiendo solo el value del Map devuelto
      // reduce recorre toda la lista
      // resultado.values.reduce((acumulado, nuevoValor) => acumulado + nuevoValor);
      final suma = resultado.values.reduce((a, b) => a + b);
      expect(suma, 10.00);
    });

    // PRUEBA 2
    test('Dividir 8.07€ entre 8 personas (El último recibe 1 céntimo menos)', () {
      final double total = 8.07;

      final participantes = [
        'Jose', // 1
        'Miguel', // 2
        'Hector', // 3
        'Carlos', // 4
        'Lucía', // 5
        'David', // 6
        'Sofía', // 7
        'Manu' // 8
      ];

      final resultado = controller.calcularDistribucion(total, participantes);

      // 8.07 / 8 = 1.00 sobra 0.07
      // Los 7 primeros se llevan 1.01
      // El último (Manu) se lleva 1.00

      expect(resultado['Jose'], 1.01);
      expect(resultado['Miguel'], 1.01);
      expect(resultado['Hector'], 1.01);
      expect(resultado['Carlos'], 1.01);
      expect(resultado['Lucía'], 1.01);
      expect(resultado['David'], 1.01);
      expect(resultado['Sofía'], 1.01);
      expect(resultado['Manu'], 1.00); // Manu es el único que no paga

      // Auditoría final: Que no se pierda dinero
      final suma = resultado.values.reduce((a, b) => a + b);
      // Usamos toStringAsFixed(2) trunca a 2 decimales
      expect(double.parse(suma.toStringAsFixed(2)), 8.07);
    });

    //jose@jose-G5-KF:~/StudioProjects/compartimos_gastos_app$ flutter test test/calculos_test.dart
    // 00:00 +2: All tests passed!
  });
}
