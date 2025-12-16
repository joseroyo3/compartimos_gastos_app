import 'package:compartimos_gastos/screens/main/group_screen.dart';
import 'package:compartimos_gastos/screens/main/profile_screen.dart';
import 'package:flutter/material.dart';

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});

  @override
  State<MainNavigationController> createState() =>
      _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  int _selectedIndex = 0; //iniciamos en 0, que es group

  // Usamos 'late' para inizializar las paginas en el initState
  // en el futuro necesitaremos pasar 'context' o argumentos a las pantallas para el cambio de color
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // El orden de esta lista debe coincidir estrictamente con el de los BottomNavigationBarItem
    _pages = [const GroupScreen(), const ProfileScreen()];
  }

  void _onItemTapped(int index) {
    // setState es necesario para reconstruir el Scaffold y mostrar la nueva página seleccionada
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Renderizamos el widget correspondiente al índice actual
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Usamos fixed para que los iconos no se muevan al seleccionarlos (estilo material estándar)
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Grupos',
          ), // 0
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ), // 1
        ],
      ),
    );
  }
}
