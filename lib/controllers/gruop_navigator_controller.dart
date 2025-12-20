import 'package:flutter/material.dart';
import '../../controllers/themes_controller.dart';
import '../../models/group_model.dart';
import '../../widgets/appbar_custom.dart';

import '../screens/main/group_screens/balance_screen.dart';
import '../screens/main/group_screens/group_screen.dart';
import '../screens/main/group_screens/settings_group_screen.dart';
import '../screens/main/group_screens/shopping_list_screen.dart';

class GroupNavigatorScreen extends StatefulWidget {
  final GroupModel groupModel;

  const GroupNavigatorScreen({super.key, required this.groupModel});

  @override
  State<GroupNavigatorScreen> createState() => _GroupNavigatorScreenState();
}

class _GroupNavigatorScreenState extends State<GroupNavigatorScreen> {
  int _currentIndex = 0;

  late List<String> _titles;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _titles = [
      widget.groupModel.nombre, // Pestaña 0
      'Balance', // Pestaña 1
      'Lista de Compra' // Pestaña 2
    ];

    _pages = [
      // 1. INICIO
      GroupScreen(groupModel: widget.groupModel),

      // 2. BALANCE
      BalanceScreen(groupModel: widget.groupModel),

      // 3. LISTA DE COMPRA
      ShoppingListScreen(groupModel: widget.groupModel),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Color colorGrupo = Color(widget.groupModel.colorValue);

    return Theme(
      data: ThemeController.crearTema(colorGrupo),
      child: Scaffold(
        appBar: _currentIndex == 0
            ? null // La pestaña 0 tiene su propia AppBar en GroupScreen
            : CustomAppBar(
                title: _titles[_currentIndex],
                showLogout: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Ajustes',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsGroupScreen(
                              groupModel: widget.groupModel),
                        ),
                      );
                    },
                  ),
                ],
              ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          // Usamos 'fixed' para que tenga el mismo tamaño y comportamiento que el Main
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorGrupo,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: 'Balance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket),
              label: 'Lista',
            ),
          ],
        ),
      ),
    );
  }
}
